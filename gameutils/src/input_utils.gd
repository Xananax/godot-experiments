class_name InputUtils


static func get_inputs_list(property_name: String, prefixes: Array[String] = [], skip_prefixes: Array[String] = ["ui"]) -> Dictionary[String, Variant]:
	var current_category := "main"
	var categories: Dictionary[String, Array] = {
		"main": []
	}
	for prop in ProjectSettings.get_property_list():
		var prop_name: String = prop.get("name", "")
		if prop_name.begins_with('input/'):
			prop_name = prop_name.replace('input/', '') 
			prop_name = prop_name.substr(0, prop_name.find("."))
			var should_skip := false
			for prefix in skip_prefixes:
				if prop_name.begins_with(prefix + "_"):
					should_skip = true
					break
			if should_skip:
				continue
			for prefix in prefixes:
				if prop_name.begins_with(prefix + "_"):
					current_category = prefix
				else:
					current_category = "main"
			var actions: Array = categories.get(current_category, [])
			if not actions.has(prop_name):
				actions.append(prop_name)
				categories[current_category] = actions
	
	var actions: Array = []
	for category_actions in categories.values():
		actions.append_array(category_actions)


	var hint_string = ",".join(actions)
	
	var dict: Dictionary[String, Variant] = {
		name = property_name,
		type = TYPE_STRING_NAME,
		hint = PROPERTY_HINT_ENUM,
		hint_string = hint_string
	}
	
	return dict
