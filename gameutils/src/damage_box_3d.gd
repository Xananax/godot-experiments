
## Hitbox and Hurtbox for 3D collisions.
##
## This class is used to create hitboxes and hurtboxes in 3D space. It provides some nice conveniences to 
## make it easier to work with dealing and receiving damage.
## [DamageBox3D] can be set as Hitbox or Hurtbox by setting the [is_hit_box] and [is_hurt_box] properties.
## These properties map the collision layers 31 and 32 respectively (which means those layers are reserved).[br]
## [br]
## [DamageBox3D] also provides a [member DamageBox3D.hitbox_damage] property to set the amount of damage
## the hitbox deals and a [member DamageBox3D.hurtbox_resistance] property to set the amount of damage
## the hurtbox receives. These values aren't used directly by the class to keep it open.[br]
## [br]
## This class depends on [PhysicsUtils].
@tool
class_name DamageBox3D extends Area3D

## Emitted when the hit box hits a hurt box.
signal dealt_damage(to_hurt_box: DamageBox3D)
## Emitted when the hurt box is hit by a hit box.
signal was_hit(by_hit_box: DamageBox3D)
## Emitted when the hurt box's resistance is depleted.
signal resistance_depleted

## The amount of damage the hit box deals.
var hitbox_damage := 1
## The amount of damage the hurt box receives.
var hurtbox_resistance := 1: set = set_hurtbox_resistance

## Proxy for collision_layer
var _physics_is_a: int = 0: set = set_is_a
## Proxy for collision_mask
var _physics_looks_at: int = 0: set = set_monitors

## If [code]true[/code], this damage box can inflict damage
@export var is_hit_box := false: set = set_is_hit_box
## If [code]true[/code], this damage box receives damage
@export var is_hurt_box := false: set = set_is_hurt_box


var _temporarily_disable_feedback_loop := false

func _init() -> void:
	monitoring = true
	monitorable = true
	_physics_is_a = collision_layer
	_physics_looks_at = collision_mask
	area_entered.connect(func _on_area_entered(area: Area3D) -> void:
		if area is DamageBox3D:
			_on_damage_box_entered(area as DamageBox3D)
	)


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if is_hurt_box == true:
		list.append({
			name = "hurtbox_resistance",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		})
	if is_hit_box:
		list.append({
			name = "hitbox_damage",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		})
	list.append_array([
		{
			name = "Category",
			type = TYPE_NIL,
			hint_string = "_physics_",
			usage = PROPERTY_USAGE_GROUP
		},
		PhysicsUtils.get_physics_layers("_physics_is_a"),
		{
			name = "Monitors",
			type = TYPE_NIL,
			hint_string = "_physics_",
			usage = PROPERTY_USAGE_GROUP
		},
		PhysicsUtils.get_physics_layers("_physics_looks_at")
	])
	return list



func _on_damage_box_entered(damage_box: DamageBox3D) -> void:
	# Each damage box is responsible of emitting its own signals
	if is_hit_box and damage_box.is_hurt_box:
		dealt_damage.emit(damage_box)
	if is_hurt_box and damage_box.is_hit_box:
		was_hit.emit(damage_box)



func set_is_a(new_flags: int) -> void:
	_physics_is_a = new_flags
	collision_layer = _physics_is_a
	if _temporarily_disable_feedback_loop:
		return
	is_hurt_box = (_physics_is_a & PhysicsUtils.LAYER_HURTBOX) != 0
	is_hit_box = (_physics_is_a & PhysicsUtils.LAYER_HITBOX) != 0


func set_monitors(new_flags: int) -> void:
	_physics_looks_at = new_flags
	collision_mask = _physics_looks_at


func set_is_hurt_box(new_value: bool) -> void:
	is_hurt_box = new_value
	notify_property_list_changed()
	_temporarily_disable_feedback_loop = true
	if is_hurt_box:
		_physics_is_a |= PhysicsUtils.LAYER_HURTBOX
	else:
		_physics_is_a &= ~PhysicsUtils.LAYER_HURTBOX
	_temporarily_disable_feedback_loop


func set_is_hit_box(new_value: bool) -> void:
	is_hit_box = new_value
	notify_property_list_changed()
	_temporarily_disable_feedback_loop = true
	if is_hit_box:
		_physics_is_a |= PhysicsUtils.LAYER_HITBOX
	else:
		_physics_is_a &= ~PhysicsUtils.LAYER_HITBOX
	_temporarily_disable_feedback_loop = false


func set_hurtbox_resistance(new_value: int) -> void:
	hurtbox_resistance = new_value
	if hurtbox_resistance <= 0:
		resistance_depleted.emit()
