## A parser for the Godot Conversation script format.
##
## This script is used to parse a custom script format for dialogues.
## It is extremely simple and won't be able to do much, but it serves 
## as an example for how simple this kind of thing may be.
class_name ConversationScriptParser


## Ensures any kind of string passed is normalized to a valid identifier
## by replacing spaces and dashes with underscores and converting to lowercase
static func _normalize_identifier(prefix: String, text: String) -> String:
	return prefix + text \
		.replace(" ", "_")\
		.replace("-", "_")\
		.to_lower()


## Ensures any kind of string passed is normalized to a valid function name
static func _valid_func_name(text: String) -> String: 
	return _normalize_identifier("conversation_", text)


## Ensures any kind of string passed is normalized to a variable name
static func _valid_variable_name(text: String) -> String:
	return _normalize_identifier("actor_", text)


## Compiles a string of Conversation script into a GDScript source code
## and returns it as a string.
static func compile(text: String) -> String:
	var r := RegEx.new()
	r.compile("(?:(?:^|\\n)\\n*#+\\s?)(?<name>.*)\\n+(?<body>[\\s\\S]+?)(?=\\n#|$)")
	var actors: Dictionary[String, String] = {}
	var last_actor := ""
	var code := PackedStringArray()
	for m in r.search_all(text):
		var section_name := m.get_string("name").strip_edges()
		var section_body := m.get_string("body").strip_edges()
		var section_ref := _valid_func_name(section_name)
		code.append("\n")
		code.append("func " + section_ref + "() -> void:")
		for line in section_body.split("\n"):
			line = line.strip_edges()
			if line.length() == 0:
				continue
			var choice_index := line.find("->")
			if choice_index > 0:
				var parts := line.split("->")
				var choice_text = parts[0].strip_edges().replace('"', '\\"')
				var choice_destination = _valid_func_name(parts[1].strip_edges())
				code.append("\tchoice(\"%s\", %s)" % [choice_text, choice_destination])
			else:
				var parts := line.split(":")
				var actor := ""
				if parts.size() == 2:
					actor = parts[0].strip_edges()
					line = parts[1].strip_edges().replace('"', '\\"')
					var actor_ref := _valid_variable_name(actor)
					actors[actor_ref] = actor
					if actor_ref != last_actor:
						code.append("\tactor(%s)" % [ actor_ref ])
						last_actor = actor_ref
					code.append("\tsay(\"%s\")" % [line])
				else:
					line = line.replace('"', '\\"')
					code.append("\tsay(\"%s\")" % [line])
	
	var header := PackedStringArray(["## Auto-Generated, do not modify directly","extends Conversation", "\n"])
	
	for actor_ref in actors:
		var actor_name = actors[actor_ref]
		header.append("var %s := Actor.Make(\"%s\")" % [ actor_ref, actor_name ])
	
	header.append_array(code)
	return "\n".join(header)


## Loads a text file and compiles it into a GDScript source code, then instantiates
## it and returns the instance.[br]
## This is the main entry point for the parser.[br]
## If the file cannot be opened, or the compilation otherwise fails, this
## method returns [code]null[/code].
static func compile_file(file_path: String) -> Conversation:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file %s" % [file_path])
		return null
	var content := file.get_as_text()
	var code := compile(content)
	var new_script := GDScript.new()
	new_script.source_code = code;
	new_script.reload()
	var instance := new_script.new() as Conversation
	assert(instance != null, "Could not compile dialogue file %s" % [file_path])
	return instance
