## A Button that allows the user to remap an action input.
## It can display an icon.
@tool
class_name RemapperButton extends Button


var action_name: StringName = ""
var _waiting_for_input := false

func _init() -> void:
	toggle_mode = true


func _toggled(toggled_on: bool) -> void:
	set_process_unhandled_input(button_pressed)
	_waiting_for_input = toggled_on
	release_focus()


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append(InputUtils.get_inputs_list("action_name"))
	return properties


func _unhandled_input(event: InputEvent) -> void:
	button_pressed = false
	if event.is_action_pressed("ui_cancel"):
		return
	if event.pressed:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		get_button_names()


func get_events() -> EventByType:
	var by_type := EventByType.new()
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			by_type.key.append(event)
		elif event is InputEventJoypadButton:
			by_type.button.append(event)
		elif event is InputEventMouseButton:
			by_type.mouse.append(event)
	return by_type


func get_button_names():
	var by_type := get_events()
	var label := " ".join([ 
		by_type.key[0].as_text_key_label() if by_type.key.size() > 0 else "",
		by_type.button[0].as_text() if by_type.button.size() > 0 else "",
		by_type.mouse[0].as_text() if by_type.mouse.size() > 0 else ""
	])
	text = label

class EventByType:
	var key: Array[InputEventKey] = []
	var button: Array[InputEventJoypadButton] = []
	var mouse: Array[InputEventMouseButton] = []
