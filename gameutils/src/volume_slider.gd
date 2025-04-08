## Handles sound volume.
##
## Depends on [VolumeUtils]. Syncs volume and muting; if the volume is set to
## [code]0[/code], volume will be muted.[br]
## This is an abstract node and can't be instanciated in the editor. Instead,
## create a VSlider or HSlider and assign this script to it.
@tool
class_name VolumeSlider extends Slider

## The index of the audio bus used by this slider.
var audio_bus_idx := 0: set = set_audio_bus_idx


func _init() -> void:
	theme_type_variation = "VolumeSlider"
	min_value = 0
	max_value = 1.0
	step = 0.05
	set_audio_bus_idx(audio_bus_idx)
	VolumeUtils.volume_changed.connect(_on_volume_changed)


func _value_changed(new_value: float) -> void:
	if Engine.is_editor_hint():
		return
	VolumeUtils.set_volume(audio_bus_idx, new_value)



func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append(VolumeUtils.get_busses_list("audio_bus_idx"))
	return list


func set_audio_bus_idx(new_audio_bus_idx: int) -> void:
	audio_bus_idx = new_audio_bus_idx
	value = VolumeUtils.get_volume(audio_bus_idx)


func _on_volume_changed(changed_audio_bus_idx: int, new_volume: float) -> void:
	if changed_audio_bus_idx == audio_bus_idx:
		set_value(new_volume)
