## Utilities for working with physics layers in Godot.
##
## This class provides methods to get the physics layers as a property specifier,
## check if a layer is a hitbox or hurtbox, and to set the physics layers.
class_name PhysicsUtils

const LAYER_HITBOX := 1 << 30
const LAYER_HURTBOX := 1 << 31


## Returns a property specifier suitable to be used in the [method Object._get_property_list]
## method, containing the physics layers by name.[br]
## By default, the method will only use named layers.[br]
## The two last layers are reserved for hitboxes and hurtboxes.
static func get_physics_layers(property_name: String, skip_unnamed_layers := true) -> Dictionary[String, Variant]:
	var flags := PackedStringArray()
	for i in range(0, 30):
		var setting := "layer_names/2d_physics/layer_%s" % [i+1]
		var layer_name = ProjectSettings.get_setting(setting)
		if layer_name == "":
			if skip_unnamed_layers:
				continue
			layer_name = "Layer %s" % [i+1]
		var value := 1 << i
		var hint_string := "%s:%d" % [layer_name, value]
		flags.append(hint_string)
	flags.append("%s:%s" % ["HitBox", LAYER_HITBOX ])
	flags.append("%s:%s" % ["HurtBox", LAYER_HURTBOX ])
	var hint_string = ",".join(flags)
	var dict: Dictionary[String, Variant] = {
		name = property_name,
		type = TYPE_INT,
		hint = PROPERTY_HINT_FLAGS,
		hint_string = hint_string
	}
	return dict


static func is_hit_box(layer: int) -> bool:
	return (layer & LAYER_HITBOX) != 0

static func is_hurt_box(layer: int) -> bool:
	return (layer & LAYER_HURTBOX) != 0
