extends "res://mods/InverseKinematicsRig/WeaponEffect.gd"

class_name WeaponRecoilEffect

const RECOIL_PROFILE = preload("res://mods/BetterRecoil/RecoilProfile.gd")
const RECOIL_SHOT = preload("res://mods/BetterRecoil/RecoilShot.gd")

@export var profile : RECOIL_PROFILE

var is_aiming := false
var active_shots : Array[RECOIL_SHOT] = []

func add_shot() -> void:
	if enabled == false:
		return
	
	if profile == null:
		return
		
	var recoil_shot = RECOIL_SHOT.new()
	
	# Recoil profile curves shouldnt be null. The curve can be empty, but not null!
	recoil_shot.pitch_degrees = randf_range(profile.pitch_range_degrees.x, profile.pitch_range_degrees.y)
	recoil_shot.kickback_metres = randf_range(profile.kickback_range_metres.x, profile.kickback_range_metres.y)
	recoil_shot.yaw_degrees = randf_range(profile.yaw_range_degrees.x, profile.yaw_range_degrees.y)
	recoil_shot.roll_degrees = randf_range(profile.roll_range_degrees.x, profile.roll_range_degrees.y)
	recoil_shot.lift_metres = randf_range(profile.lift_range_metres.x, profile.lift_range_metres.y)
	recoil_shot.follow_through_pitch_degrees = randf_range(profile.follow_through_pitch_range_degrees.x, profile.follow_through_pitch_range_degrees.y)
	recoil_shot.follow_through_yaw_degrees = randf_range(profile.follow_through_yaw_range_degrees.x, profile.follow_through_yaw_range_degrees.y)
	
	active_shots.append(recoil_shot)

func update_effect(delta: float) -> void:
	offset = Transform3D.IDENTITY
	
	if profile == null:
		return
	
	if _is_valid_curves() == false:
		return
	
	if profile.shot_duration_seconds <= 0.0:
		return
		
	var total_pitch_degrees = 0.0
	var total_kickback_metres = 0.0
	var total_yaw_degrees = 0.0
	var total_roll_degrees = 0.0
	var total_lift_metres = 0.0
	var total_follow_through_pitch_degrees = 0.0
	var total_follow_through_yaw_degrees = 0.0
	
	var remaining_shots : Array[RECOIL_SHOT] = []
	
	for shot in active_shots:
		shot.age_seconds += (delta * profile.playback_speed)
		var main_active := shot.age_seconds < profile.shot_duration_seconds
		var follow_through_active := profile.follow_through_duration_seconds > 0 and shot.age_seconds < profile.follow_through_duration_seconds
		
		if main_active:
			var normalized_time = shot.age_seconds / profile.shot_duration_seconds
			total_pitch_degrees += shot.pitch_degrees * profile.pitch_curve.sample(normalized_time)
			total_kickback_metres += shot.kickback_metres * profile.kickback_curve.sample(normalized_time)
			total_yaw_degrees += shot.yaw_degrees * profile.yaw_curve.sample(normalized_time)
			total_roll_degrees += shot.roll_degrees * profile.roll_curve.sample(normalized_time)
			total_lift_metres += shot.lift_metres * profile.lift_curve.sample(normalized_time)
		
		if follow_through_active:
			var normalized_time = shot.age_seconds / profile.follow_through_duration_seconds
			total_follow_through_pitch_degrees += shot.follow_through_pitch_degrees * profile.follow_through_curve.sample(normalized_time)
			total_follow_through_yaw_degrees += shot.follow_through_yaw_degrees * profile.follow_through_curve.sample(normalized_time)
			
		if main_active or follow_through_active:
			remaining_shots.append(shot)
	
	active_shots = remaining_shots
	
	if is_aiming:
		total_pitch_degrees *= profile.ads_rotation_multiplier
		total_yaw_degrees *= profile.ads_rotation_multiplier
		total_roll_degrees *= profile.ads_rotation_multiplier
		total_kickback_metres *= profile.ads_translation_multiplier
		total_lift_metres *= profile.ads_translation_multiplier
		total_follow_through_pitch_degrees *= profile.ads_rotation_multiplier
		total_follow_through_yaw_degrees *= profile.ads_rotation_multiplier
	
	offset.origin.z = total_kickback_metres
	offset.origin.y = total_lift_metres
	
	var rotation = Vector3(
		deg_to_rad(total_pitch_degrees), 
		deg_to_rad(total_yaw_degrees), 
		deg_to_rad(total_roll_degrees)
	)
	offset.basis = Basis.from_euler(rotation)
	
	var rotated_pivot = offset.basis * profile.rotation_pivot_metres
	var pivot_compensation = profile.rotation_pivot_metres - rotated_pivot
	
	offset.origin += pivot_compensation
	
	var follow_through_offset := Transform3D.IDENTITY
	var follow_through_rotation := Vector3(
		deg_to_rad(total_follow_through_pitch_degrees), 
		deg_to_rad(total_follow_through_yaw_degrees), 
		0.0
	)
		
	follow_through_offset.basis = Basis.from_euler(follow_through_rotation)
	
	var follow_through_pivot = follow_through_offset.basis * profile.follow_through_pivot_metres
	
	follow_through_offset.origin = profile.follow_through_pivot_metres - follow_through_pivot
	
	# combine main recoil and follow through recoil offsets
	offset = follow_through_offset * offset

func reset_effect() -> void:
	super.reset_effect()
	active_shots.clear()
	is_aiming = false

func _is_valid_curves() -> bool:
	if profile.pitch_curve == null:
		return false
	
	if profile.kickback_curve == null :
		return false
		
	if profile.yaw_curve == null :
		return false
	
	if profile.roll_curve == null:
		return false
	
	if profile.lift_curve == null:
		return false
	
	if profile.follow_through_curve == null:
		return false
	
	return true
	
