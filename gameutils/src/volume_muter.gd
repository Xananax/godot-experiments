## Mutes and umutes sounds.
##
## Depends on [VolumeUtils]. Syncs the volume and muted state (muting will set
## the volume to [code]0[/code])
@tool
class_name VolumeMuter extends CheckButton


## The index of the audio bus used by this slider.
var audio_bus_idx := 0: set = set_audio_bus_idx


func _init() -> void:
	theme_type_variation = "VolumeMuter"
	toggle_mode = true
	VolumeUtils.mute_toggled.connect(_on_mute_toggled)
	set_audio_bus_idx(audio_bus_idx)

func _ready() -> void:
	button_pressed = VolumeUtils.get_mute(audio_bus_idx)


func _toggled(toggled_on: bool) -> void:
	if Engine.is_editor_hint():
		return
	VolumeUtils.set_mute(audio_bus_idx, toggled_on)


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append(VolumeUtils.get_busses_list("audio_bus_idx"))
	return list


func set_audio_bus_idx(new_audio_bus_idx: int) -> void:
	audio_bus_idx = new_audio_bus_idx
	button_pressed = VolumeUtils.get_mute(audio_bus_idx)


func _on_mute_toggled(toggled_bus_idx: int, is_muted: bool) -> void:
	if toggled_bus_idx == audio_bus_idx:
		set_pressed_no_signal(is_muted)
