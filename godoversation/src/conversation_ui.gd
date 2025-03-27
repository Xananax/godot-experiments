extends Control

@export var _texts_container: VBoxContainer = null
@export var _buttons_container: HBoxContainer = null
@export var conversation_script: GDScript = null: set = set_conversation_script

var _conversation: Conversation
var chars_per_second := 120.0

# Imagine those conversations are loaded through some other mean.
var _conversation_1 := preload("./conversation_example.gd").new()
var _conversation_2 := ConversationScriptParser.compile_file("./example.conversation.txt")

# those buttons figure events happening in the game, such as talking with an NPC
@onready var _button_start: Button = %ButtonStart
@onready var _button_start_wolf: Button = %ButtonStartWolf
@onready var _button_start_act_1: Button = %ButtonStartAct1
@onready var _texture_rect: TextureRect = %TextureRect
@onready var _window: Window = %Window


func _ready() -> void:
	_button_start.pressed.connect(func() -> void:
		set_conversation(_conversation_1)
		_conversation.default_entry = "start_merchant"
		_conversation.default_start()
		_toggle_buttons_enabled_state(false)
	)
	_button_start_wolf.pressed.connect(func() -> void:
		set_conversation(_conversation_1)
		_conversation.default_entry = "start_wolf"
		_conversation.default_start()
		_toggle_buttons_enabled_state(false)
	)
	_button_start_act_1.pressed.connect(func() -> void:
		set_conversation(_conversation_2)
		_conversation.default_entry = "conversation_act_1"
		_conversation.default_start()
		_toggle_buttons_enabled_state(false)
	)


func reset() -> void:
	for child in _texts_container.get_children():
		_texts_container.remove_child(child)
	for child in _buttons_container.get_children():
		_buttons_container.remove_child(child)


func set_conversation_script(new_script: GDScript) -> void:
	if new_script == conversation_script:
		return
	var instance := new_script.new() as Conversation
	var instance_is_valid = instance != null and instance is Conversation
	assert(instance_is_valid, "Script %s is not a Conversation instance" % [new_script.resource_path])
	conversation_script = new_script
	set_conversation(instance)


func set_conversation(new_conversation: Conversation) -> void:
	if _conversation != null:
		_conversation.conversation_started.disconnect(_on_conversation_started)
		_conversation.quit_request.disconnect(_on_conversation_ended)
		if _conversation.has_signal("open_merchant_inventory"):
			_conversation.open_merchant_inventory.disconnect(_window.popup)
	_conversation = new_conversation
	_conversation.conversation_started.connect(_on_conversation_started)
	_conversation.quit_request.connect(_on_conversation_ended)
	if _conversation.has_signal("open_merchant_inventory"):
		_conversation.open_merchant_inventory.connect(_window.popup)


func _on_conversation_started() -> void:
	reset()
	var tween := create_tween()
	tween.tween_interval(0.3)
	# this simple implementation will draw all the lines at once. Since each
	# conversational node can have a different actor, this won't work if you have
	# multiple people speaking. In that case, you should wait for each node to finish before
	# picking the next.
	for node in _conversation.current_nodes:
		var actor := node.actor
		var actor_name := (actor.name if actor else "narrator") + ": "
		_texture_rect.texture = actor.portrait if actor else null
		for line in node.lines:
			var rich_text_label := RichTextLabel.new()
			rich_text_label.fit_content = true
			rich_text_label.bbcode_enabled = true
			rich_text_label.visible_ratio = 0
			
			rich_text_label.bbcode_text = actor_name + line
			
			var duration: float = rich_text_label.text.length() / chars_per_second
			tween.tween_property(rich_text_label, "visible_ratio", 1.0, duration)

			_texts_container.add_child(rich_text_label)
		
		tween.finished.connect(func() -> void:
			for choice in node.choices:
				var button := choice.make_button()
				_buttons_container.add_child(button)
		)


func _on_conversation_ended() -> void:
	_toggle_buttons_enabled_state(true)
	reset()


func _toggle_buttons_enabled_state(enabled: bool) -> void:
	_button_start.disabled = not enabled
	_button_start_wolf.disabled = not enabled
	_button_start_act_1.disabled = not enabled
