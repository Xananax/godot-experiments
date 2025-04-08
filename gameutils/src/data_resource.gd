## Utilities for serializing and deserializing objects
##
## Resources in Godot are amazing, but they have one problem and a half.
## the big problem is reliance on specific file paths, and no clear versioning system.
## This has two consequences: [br]
## - If you need to move a resource script after having shipped a game, the
## resources saved before won't work.[br]
## - If you change the resource script's code, you have to be either careful
## to leave it compatible with the previous version, or create new versions
## and an upgrade path.[br]
## The last small problem is that if a resource has a [code]script[/code]
## field, Godot will happily instantiate it and run its [code]_init[/code]
## function. This is a bit of a theoretical problem (people routinely
## download insecure binaries from the internet), but it'd be nice if this
## wasn't possible.[br]
##
## This serializer solves these problems partially.[br]
## It saves a resource to an ini file, which means the resource script path
## is not part of the serialized data. This frees you from having to keep the
## resource path constant.[br]
## It does [b]not[/b] protect you from versioning woes, but because it's possible
## to restore the ini file to an arbitrary resource, managing them is easier.[br]
## Finally, you can avoid dangerous properties in two ways:[br]
## - You can skip some properties by property name. By default [code]"script"[/code]
## is skipped.[br]
## - The deserializer will automatically called validation functions. For example,
## if you have a property called [code]health[/code], the deserializer will attempt
## to call a function called [code]_validate_health[/code]. You can use that and return
## [code]false[/code] to skip setting the property. This function can also be used to
## upgrade old versions. For example, say a property [code]health[/code] became [code]hp[/code]:
## [code]
## class_name PlayerData extends Resource
##
## # we removed this value
## # var health := 5
## var hp := 5
##
## func _validate_health(value: int) -> bool:
## 	hp = value
## 	return false
## [/code]
class_name DataUtils

## What properties will be skipped by default
static var DEFAULT_SKIP_PROPERTIES := PackedStringArray(["script"])


## Saves the given object to a config file. Respects [code]@export[/code]
## annotations and will only save exported properties. If properties have an
## editor category, this category will be used to separate serialized properties
## in the saved structure.[br]
## - [param object] the object to serialize
## - [param path] the path to save to
## - [param default_catgory_name] the name to use as a category if no category was
##   found in the script.
static func save_object(object: Object, path: String, default_category_name := "main") -> int:
	var config := ConfigFile.new()
	serialize_object_to_config_file(object, config, default_category_name)
	return config.save(path)


## Serializes the given object to a config file. Respects [code]@export[/code]
## annotations and will only save exported properties. If properties have an
## editor category, this category will be used to separate serialized properties
## in the saved structure.[br]
## - [param object] the object to serialize[br]
## - [param config_fole] the config file to populate[br]
## - [param default_catgory_name] the name to use as a category if no category was
##   found in the script.
static func serialize_object_to_config_file(object: Object, config_file: ConfigFile, default_category_name := "main") -> void:
	var category := default_category_name
	for property in object.get_property_list():
		var usage := property.get("usage", 0) as int
		if usage & (PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP):
			category = property.name
		elif (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) && usage & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR):
			config_file.set_value(category, property.name, object.get(property.name))


## Populates a provided object from the config file found at the provided path.[br]
## Runs setters if there are any; silently does nothing if a property doesn't exist
## - [param object] the object to restore to[br]
## - [param path] the path to load from.[br]
## Returns [code]OK[/code], or an error code. See [method ConfigFile.load] for more information.
static func restore_object(object: Object, path: String) -> int:
	var config := ConfigFile.new()
	var load_result := config.load(path)
	if load_result != OK:
		return load_result
	restore_object_from_config_file(object, config)
	return OK


## Populates a provided object from the given config file.[br]
## Runs setters if there are any; silently does nothing if a property doesn't exist.[br]
## This method provides an opportunity to validate the data going in; for a given
## property [code]prop[/code], the deserializer will attempt to call a function called
## [code]_validate_prop[/code] if it exists. This function should return a boolean. Any value
## other than specifically [code]true[/code] will be assumed invalid.[br]
## This function can be made safe in two ways:
## - blacklisting properties th[br]
## - [param object] the object to restore to.[br]
## - [param config_file] the config file to load from.[br]
## - [param skip] a set of properties to skip. Defaults to ["script"].[br]
static func restore_object_from_config_file(object: Object, config_file: ConfigFile, skip := DEFAULT_SKIP_PROPERTIES) -> void:
	for section in config_file.get_sections():
		for property in config_file.get_section_keys(section):
			if skip.has(property):
				continue
			var value = config_file.get_value(section, property, object.get(property))
			var validate_func_name := "_validate_%s" % [property]
			var is_valid: bool = (not object.has_method(validate_func_name)) or (object.call(validate_func_name, value) == true)
			if (property in object) and is_valid:
				object.set(property, value)
