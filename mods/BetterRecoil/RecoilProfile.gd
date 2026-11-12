extends Resource

class_name RecoilProfile

@export var profile_name : String
@export var playback_speed : float = 1.1
@export var pitch_range_degrees := Vector2(-12.0, -9.0)
@export var kickback_range_metres := Vector2(-0.016, -0.014)
@export var rotation_pivot_metres := Vector3.ZERO
@export var yaw_range_degrees := Vector2(-0.3, 0.3)
@export var roll_range_degrees := Vector2(-0.5, 0.5)
@export var shot_duration_seconds := 0.67

@export var pitch_curve : Curve
@export var kickback_curve : Curve
@export var roll_curve : Curve
@export var yaw_curve : Curve

@export var lift_range_metres := Vector2(0.008, 0.012)
@export var lift_curve : Curve

@export var follow_through_pitch_range_degrees := Vector2.ZERO
@export var follow_through_yaw_range_degrees := Vector2.ZERO
@export var follow_through_duration_seconds := 0.8
@export var follow_through_curve : Curve
@export var follow_through_pivot_metres := Vector3.ZERO

@export var ads_rotation_multiplier := 0.6
@export var ads_translation_multiplier := 0.6
