extends Node

const RIG_SERVICE = preload("res://mods/InverseKinematicsRig/IKRigService.gd")
const RECOIL_EFFECT = preload("res://mods/BetterRecoil/WeaponRecoilEffect.gd")
const IK_RIG = preload("res://mods/InverseKinematicsRig/IKRig.gd")
var game_data = preload("res://Resources/GameData.tres")

const PROFILES = {
	"pistol": preload("res://mods/BetterRecoil/RecoilProfile_Pistol.tres"),
	"smg": preload("res://mods/BetterRecoil/RecoilProfile_SMG.tres"),
	"assault_rifle": preload("res://mods/BetterRecoil/RecoilProfile_AssaultRifle.tres"),
	"carbine": preload("res://mods/BetterRecoil/RecoilProfile_Carbine.tres"),
	"sniper": preload("res://mods/BetterRecoil/RecoilProfile_Sniper.tres"),
	"shotgun": preload("res://mods/BetterRecoil/RecoilProfile_Shotgun.tres"),
	"rifle": preload("res://mods/BetterRecoil/RecoilProfile_Rifle.tres"),
}

const _MOD_LIB = "RTVModLib"

var rig_service : RIG_SERVICE

var _effects_by_rig : Dictionary = {}

var mod_lib = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var backend = get_node_or_null("/root/InverseKinematicsRig")
	
	if is_instance_valid(backend) == false:
		print("Inverse Kinematics Rig mod is a required dependency which needs to be added first! ")
		set_process(false)
		return
	
	if backend.is_node_ready() == false:
		await backend.ready
	
	rig_service = backend.rig_service
	
	if is_instance_valid(rig_service) == false:
		print("Could not find ik rig service")
		set_process(false)
		return
	else:
		print("Found ik rig service!")
	
	rig_service.rig_registered.connect(_on_rig_registered)
	rig_service.rig_unregistered.connect(_on_rig_unregistered)
	
	var rigs = rig_service.get_registered_rigs()
	
	for rig_id in rigs:
		_on_rig_registered(rig_id, rigs[rig_id])
	
	
	if Engine.has_meta(_MOD_LIB):
		mod_lib = Engine.get_meta(_MOD_LIB)
	else:
		print("Metro Mod Loader is not available.")
		return
	
	if mod_lib._is_ready == true:
		_on_frameworks_ready()
	else:
		mod_lib.frameworks_ready.connect(_on_frameworks_ready)
	
func _process(_delta: float) -> void:
	for effect in _effects_by_rig.values():
		effect.is_aiming = game_data.isAiming

func _on_rig_registered(rig_id: int, rig_entry: IK_RIG) -> void:
	if _effects_by_rig.has(rig_id):
		return

	var coordinator = rig_entry.coordinator
	var weapon_skeleton = rig_entry.skeleton

	if not is_instance_valid(coordinator):
		return

	if not is_instance_valid(weapon_skeleton):
		return

	var weapon_rig = weapon_skeleton.owner
	if not is_instance_valid(weapon_rig):
		return

	var profile_key = _get_profile_key(weapon_rig)

	var effect = RECOIL_EFFECT.new()
	effect.profile = PROFILES[profile_key]
	add_child(effect)

	coordinator.register_effect(effect)
	_effects_by_rig[rig_id] = effect

	print("[Better Recoil] %s -> %s" % [weapon_rig.name, profile_key])

func _on_rig_unregistered(rig_id: int) -> void:
	if _effects_by_rig.has(rig_id) == false:
		return
	
	var effect = _effects_by_rig[rig_id]
	
	_effects_by_rig.erase(rig_id)
	
	if is_instance_valid(effect):
		effect.queue_free()

func _on_frameworks_ready() -> void:
	mod_lib.hook("recoil-applyrecoil-post", _on_shot)

func _on_shot() -> void:
	var native_recoil = mod_lib._caller
	
	if is_instance_valid(native_recoil) == false:
		return
	
	var weapon_rig = native_recoil.owner
	
	if is_instance_valid(weapon_rig) == false:
		return
	
	var weapon_skeleton = weapon_rig.get("skeleton")
	
	if is_instance_of(weapon_skeleton, Skeleton3D) == false:
		return
	
	var rig_id = weapon_skeleton.get_instance_id()
	
	if _effects_by_rig.has(rig_id) == false:
		return
	
	var effect = _effects_by_rig[rig_id]
	
	if is_instance_valid(effect):
		#disable native recoil effect
		
		native_recoil.set_physics_process(false)
		native_recoil.currentKick = Vector3.ZERO
		native_recoil.currentRotation = Vector3.ZERO
		native_recoil.transform = Transform3D.IDENTITY
		
		effect.is_aiming = game_data.isAiming
		effect.add_shot()

func _get_profile_key(weapon_rig: Node) -> String:
	if not is_instance_valid(weapon_rig):
		return "rifle"

	var weapon_data = weapon_rig.get("data")
	if not is_instance_valid(weapon_data):
		return "rifle"

	var weapon_id = weapon_data.resource_path.get_file().get_basename().to_lower()

	if weapon_id in ["aks-74u", "mk18"]:
		return "carbine"

	if weapon_id in ["svd", "vss"]:
		return "sniper"

	var weapon_type = str(weapon_data.get("weaponType")).to_lower()

	match weapon_type:
		"pistol":
			return "pistol"
		"smg":
			return "smg"
		"shotgun":
			return "shotgun"
		"bolt":
			return "sniper"
		"rifle":
			return "assault_rifle"
		_:
			return "rifle"
