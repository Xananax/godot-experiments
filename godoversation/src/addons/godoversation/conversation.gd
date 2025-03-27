## A DSL to describe conversations
##
## Godoversation is a thin wrapper over signals allowing you to write conversations ergonomically,
## using GDScript. [br]
## Because you use full GDScript, you do not need any specific plugin or wiring to tap into your
## game's systems: simply load or emit the resources you want.[br]
## [br]
## Godoversation is unopinionated, and doesn't show any UI by default. All it does it emit signals.
## You're free to use those signals in any way you prefer: for example, displaying the conversation
## in a UI; or triggering game events.[br]
## [br]
## Because conversation needs are often very specific to games, it might be surprising to know that 
## there will be no API to extend the functionality: rather, it is expected that you add your own
## functionality to Godoversation. The code [b]is itself[/b] the API, and it is kept [b]intentionally[b]
## as simple as possible. Change it, adapt it, publish your own variations, or use it as inspiration
## for something different.[br]
## [br]
## Here's an example usage:
## [code]
## class_name MyConversation extends Conversation
##
## var sophia := Actor.Make("Sophia", preload("res://assets/sophia.png"))
##
## func start() -> void:
## 	actor(sophia)
## 	say("Hey!")
## 	say("How are you?")
## 	if visits(start) > 0:
## 		say("I've asked you this %s times before" % [visits(start)])
## 	choice("I'm fine", _fine)
## 	choice("I'm not fine", _not_fine)
## 	leave_choice("I don't want to talk")
##
## func _fine() -> void:
## 	say("That's good to hear!")
## 	leave_choice("Yep! Goodbye!")
##
## func _not_fine() -> void:
## 	say("That's too bad.")
## 	say("I'll ask again, ok?")
## 	choice("Ok", start)
## 	leave_choice("No. I'm leaving")
## [/code]
## [br]
## Then start the conversation with [code]conversation.godot(start)[/code]. 
## This will start emitting signals. Here is a very simple example that only
## prints the conversation to the console:
## [code]
## func _ready() -> void:
## 	var conversation := MyConversation .new()
## 	conversation.conversation_started.connect(_on_conversation_started)
## 	conversation.quit_request.connect(_on_conversation_quit)
## 	conversation.godot(start)
##
##
## func _on_conversation_started() -> void:
## 	for node in _conversation.current_nodes:
## 	for line in node.lines:
## 		print(line)
## 		for choice in node.choices:
## 			var button := choice.make_button()
##
##
## func _on_conversation_ended() -> void:
## 	print("finished")
## 
## [/code]
## There is no way to make choices in this example, since the buttons aren't 
## used anywhere.
## [br]
## The way Godoversation works is simple and inspired by the talk 
## [url=https://www.youtube.com/watch?v=HZft_U4Fc-U&t=544s]Narrative Sorcery: Coherent Storytelling in an Open World [/url]
## by Inkle's Jon Ingold at GDC 2017.[br]
## Every function is a "node". Visiting the node increases it's [code]visit[/code] count.
## To know if a player has encountered an event before, you can count the number of visits to a specific node.
## This system isn't confined to conversations either. A node can be any method, and do anything.
##
class_name Conversation

## Emitted when the conversation starts
signal conversation_started

## emitter when a conversation ends
signal quit_request

## The nodes currently cached, as created by the last method called.
var current_nodes: Array[ConversationNode] = []
## The name of a method as a string. Calling [method default_start] will
## call the method designated by this string. 
## This is useful to call a conversation's starting entry without having
## to know what the entry point is, or to use a serialized entry point.
var default_entry: StringName
## If [code]true[/code], a "Leave" choice will be appended to any node
## that has no choices by default.
var automatically_append_leave_to_choiceless_nodes = true
## The text of the leave choice, when none is specified.
var default_leave_text := "Leave"

var _visited_conversation_nodes: Dictionary = {}


## Visits a function and marks the visit.
## When calling dialogue nodes, you should always use goto.
func goto(method: Callable) -> void:
	
	current_nodes = []
	
	method.call()
	
	_increment_visit(method)
	
	var conversation_nodes_were_created := current_nodes.size() > 0
	assert(conversation_nodes_were_created, "The function did not create any conversation parts.")
	
	if not conversation_nodes_were_created:
		return
	
	for node in current_nodes:
		if node.choices.size() == 0 and automatically_append_leave_to_choiceless_nodes == true:
			var choice_node := _create_leave_choice()
			node.choices.append(choice_node)
		var is_valid := node.lines.size() > 0 or node.choices.size() > 0
		if not is_valid:
			assert(is_valid, "A conversation node has no text and no choices.")
			return
	
	conversation_started.emit()


## If a dialog branch is currently open, returns it. Otherwise,
## creates a new dialog branch
func _get_current_conversation_node() -> ConversationNode:
	var dialog_branch: ConversationNode = current_nodes.back()
	if dialog_branch == null:
		dialog_branch = ConversationNode.new()
		current_nodes.append(dialog_branch)
	return dialog_branch


## Sets the current actor. Creates a new dialog branch
func actor(current_actor: Actor) -> void:
	var branch := ConversationNode.new()
	branch.actor = current_actor
	current_nodes.append(branch)


## Adds a line of dialog to the current node
func say(line: String) -> void:
	var dialog_branch := _get_current_conversation_node()
	var lines := dialog_branch.lines
	lines.append(line)
	dialog_branch.lines = lines


## Creates a default choice that links to a method to call.
func choice(text: String, method: Callable) -> void:
	var choice_node := Choice.new()
	choice_node.text = text
	choice_node.was_picked.connect(goto.bind(method))
	add_choice(choice_node)


func _create_leave_choice(text := default_leave_text) -> Choice:
	var choice_node := Choice.new()
	choice_node.text = text
	choice_node.was_picked.connect(quit_request.emit)
	return choice_node


## Adds a choice to leave the dialog
func leave_choice(text := default_leave_text) -> void:
	add_choice(_create_leave_choice(text))


## Appends a choice to the current conversation node
func add_choice(choice_node: Choice) -> void:
	var conversation_node := _get_current_conversation_node()
	conversation_node.choices.append(choice_node)
	

## Counts visits to a specific conversation node
func visits(method: Callable) -> int:
	var func_name := method.get_method()
	if func_name in _visited_conversation_nodes:
		return _visited_conversation_nodes[func_name] as int
	return 0


## Returns true if the conversation node has been visited at least once. 
func has_visited(method: Callable) -> bool:
	return visits(method) > 0


## Makes sure a visit to a branch is counted
func _increment_visit(method: Callable) -> void:
	var func_name := method.get_method()
	if func_name not in _visited_conversation_nodes:
		_visited_conversation_nodes[func_name] = 0
	_visited_conversation_nodes[func_name] += 1


func set_default_entry(new_entry: StringName) -> void:
	if default_entry == new_entry:
		return
	if new_entry != null:
		var found := get_conversation_nodes().has(new_entry)
		assert(found, "The default entry %s is not found" % [new_entry])
		if not found:
			return
	default_entry = new_entry


## navigates to the default entry specified in the [member default_entry].
## this is similar to calling [code]goto(some_method_name)[/code], but it
## allows to set the entry point separately, at a previous moment in the runtime.
func default_start() -> void:
	var has_default_entry := default_entry and default_entry in self
	assert(has_default_entry, "Calling default_start() without a defaul entry set")
	if not has_default_entry:
		return
	var method := self[default_entry] as Callable
	goto(method)


## Returns all method names that aren't part of the core Dialogue class.
func get_conversation_nodes() -> PackedStringArray:
	var names := PackedStringArray()
	for dict in get_method_list():
		var name := dict["name"] as String
		var args := dict["args"] as Array
		if args.size() > 0 \
			or name.begins_with("_") \
			or ["goto", "actor", "say", "choice", "add_leave_choice", "add_choice", "visits", "has_visited", "get_conversation_nodes", "Actor.Make", "Choice.run", "Choice.make_button"].has(name):
			continue
		names.append(name)
	return names


## Represents a dialog piece. Is optionally spoken by an actor.
##
## A converation node has at least some text, and has zero or more choices. 
## If a node has no choices, the default behavior of the [Conversation] class
## is to append a "Leave" choice. This can be disabled by setting
## [member Conversation.automatically_append_leave_to_choiceless_nodes] to [code]false[/code].
class ConversationNode:
	
	## The currently speaking actor. Can be null
	var actor: Actor
	
	
	## The current block of text. Each item in the array represents a paragraph,
	## or however you'd rather chunk your text
	var lines := PackedStringArray()
	
	
	## A list of choices
	var choices: Array[Choice]= []
	
	
	func _to_string() -> String:
		# warning-ignore:incompatible_ternary
		return "{%s: \"%s\" %s}"%[actor.name if actor else "NONE", lines[0].substr(0, 15) if lines.size() else "", choices]


## Represents an actor
##
## An "actor" is any entity that can speak. It is intended to be a character,
## but it can be anything. It has a name, and an optional image.[br]
## Extend it with anything that is necessary for your game. 
class Actor:
	
	## The actor's image
	var portrait: Texture
	
	## The actor's name
	var name: String
	
	
	## For debugging purposes
	func _to_string() -> String:
		return "(Actor %s)"%[name]
	
	
	## Creates a new actor
	static func Make(initial_name := "", initial_portrait: Texture = null) -> Actor:
		var actor := Actor.new()
		actor.name = initial_name
		actor.portrait = initial_portrait
		return actor


## Represents a choice
##
## A choice can generate a button. When pressed, the 
## button will call the [method Conversation.goto] method
## with the method attached to the choice.
class Choice:
	
	
	## Emitted when the choice is picked
	signal was_picked
	
	## The text shown on the button
	var text := ""
	
	
	## Runs the bound action. By default, this emits the `was_picked`
	## signal, with [Conversation] listens to.
	func run() -> void:
		was_picked.emit()
	
	
	## Creates a button that runs a choice. A simple shortcut for 
	## when all that's needed is the default button.
	func make_button(button := Button.new()) -> Button:
		button.text = text
		button.pressed.connect(run)
		return button
	
	
	## For debugging purposes.
	func _to_string() -> String:
		return "(Choice %s)"%[text]
