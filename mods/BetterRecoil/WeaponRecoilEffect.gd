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
	
	recoil_shot.pitch_degrees = randf_range(profile.pitch_range_degrees.x, profile.pitch_range_degrees.y)
	recoil_shot.kickback_metres = randf_range(profile.kickback_range_metres.x, profile.kickback_range_metres.y)
	recoil_shot.yaw_degrees = randf_range(profile.yaw_range_degrees.x, profile.yaw_range_degrees.y)
	recoil_shot.roll_degrees = randf_range(profile.roll_range_degrees.x, profile.roll_range_degrees.y)
	
	active_shots.append(recoil_shot)

func update_effect(delta: float) -> void:
	offset = Transform3D.IDENTITY
	
	if profile == null:
		return
	
	if profile.pitch_curve == null or profile.kickback_curve == null or profile.yaw_curve == null or profile.roll_curve == null:
		return
	
	if profile.shot_duration_seconds <= 0.0:
		return
		
	var total_pitch_degrees = 0.0
	var total_kickback_metres = 0.0
	var total_yaw_degrees = 0.0
	var total_roll_degrees = 0.0
	
	var remaining_shots : Array[RECOIL_SHOT] = []
	
	for shot in active_shots:
		shot.age_seconds += (delta * profile.playback_speed)
		
		if shot.age_seconds >= profile.shot_duration_seconds:
			continue
		
		var normalized_time = shot.age_seconds / profile.shot_duration_seconds
		total_pitch_degrees += shot.pitch_degrees * profile.pitch_curve.sample(normalized_time)
		total_kickback_metres += shot.kickback_metres * profile.kickback_curve.sample(normalized_time)
		total_yaw_degrees += shot.yaw_degrees * profile.yaw_curve.sample(normalized_time)
		total_roll_degrees += shot.roll_degrees * profile.roll_curve.sample(normalized_time)
		
		remaining_shots.append(shot)
	
	active_shots = remaining_shots
	
	if is_aiming:
		total_pitch_degrees *= profile.ads_rotation_multiplier
		total_yaw_degrees *= profile.ads_rotation_multiplier
		total_roll_degrees *= profile.ads_rotation_multiplier
		total_kickback_metres *= profile.ads_translation_multiplier
	
	offset.origin.z = total_kickback_metres
	
	var rotation = Vector3(deg_to_rad(total_pitch_degrees), deg_to_rad(total_yaw_degrees), deg_to_rad(total_roll_degrees))
	offset.basis = Basis.from_euler(rotation)
	
	var rotated_pivot = offset.basis * profile.rotation_pivot_metres
	var pivot_compensation = profile.rotation_pivot_metres - rotated_pivot
	
	offset.origin += pivot_compensation

func reset_effect() -> void:
	super.reset_effect()
	active_shots.clear()
	is_aiming = false
