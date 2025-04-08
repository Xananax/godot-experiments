class_name VolumeUtils
## Godot's AudioServer doesn't dispatch signals for bus volume changing, so we proxy it
##
## This is a wrapper around the audio server. Features: [br]
## - Emits signals when volumes change, or when a bus is muted[br]
## - Links the muted state and the volume state; setting volume to zero is
##   equivalent to muting the bus. Last volume is retained, and restored when unmuted.

## Emitted when the volume changes. Calls a function with the bus index and the
## volume
static var volume_changed: Signal = (func() -> Signal:
	(VolumeUtils as RefCounted).add_user_signal("volume_changed", [
		{ name = "audio_bus", type = TYPE_INT },
		{ name = "volume", type = TYPE_FLOAT }
	])
	return Signal(VolumeUtils, "volume_changed")
).call()


## Emitted when the muted state changes. Calls a function with the bus index
## and the muted state.
static var mute_toggled: Signal = (func() -> Signal:
	(VolumeUtils as RefCounted).add_user_signal("mute_toggled", [
			{ name = "audio_bus", type = TYPE_INT },
			{ name = "is_muted", type = TYPE_BOOL }
	])
	return Signal(VolumeUtils, "mute_toggled")
).call()


## Returns a property specifier suitable to be used in the [method Object._get_property_list]
## method.
static func get_busses_list(property_name := "audio_bus_idx") -> Dictionary[String, Variant]:
	var busses := PackedStringArray()
	for bus_index in AudioServer.bus_count:
		var bus_name := AudioServer.get_bus_name(bus_index)
		busses.append(bus_name)
	var dict: Dictionary[String, Variant] = {
		name = property_name,
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = ",".join(busses)
	}
	return dict



static var _last_volume: Dictionary[int, float] = {}

## Sets the volume linearly.[br]
## If the volume is set to [code]0[/code], the bus will be muted
## [param new_volume] a float between [code]0[/code] and [code]1[/code][br]
static func set_volume(audio_bus_idx: int, new_volume: float) -> void:
	var previous_volume := AudioServer.get_bus_volume_linear(audio_bus_idx)
	if is_equal_approx(previous_volume, new_volume):
		return
	_last_volume[audio_bus_idx] = previous_volume
	if new_volume <= 0:
		AudioServer.set_bus_mute(audio_bus_idx, true)
		mute_toggled.emit(audio_bus_idx, true)
	if previous_volume == 0:
		AudioServer.set_bus_mute(audio_bus_idx, false)
		mute_toggled.emit(audio_bus_idx, false)
	AudioServer.set_bus_volume_linear(audio_bus_idx, new_volume)
	volume_changed.emit(audio_bus_idx, new_volume)
	return


## Just a proxy to [method AudioServer.get_bus_volume_linear]
static func get_volume(audio_bus_idx: int) -> float:
	return AudioServer.get_bus_volume_linear(audio_bus_idx)


## Restore whichever volume was cached before a bus' volume was set to [code]0[/code].[br]
## If no prior volume was stored, [param defaultIfNotFound] is used instead
## (defaults to [code]1.0[/code]).
static func restore_previous_volume(audio_bus_idx: int, defaultIfNotFound := 1.0) -> void:
	var new_volume :=  _last_volume[audio_bus_idx] if audio_bus_idx in _last_volume else defaultIfNotFound
	set_volume(audio_bus_idx, new_volume)


## Equivalent to calling:[br]
## - [method VolumeUtils.set_volume] with a value of [code]0[/code] when muting[br]
## - [method VolumeUtils.restore_previous_volume] when unmuting[br]
static func set_mute(audio_bus_idx: int, new_mute: bool) -> void:
	if new_mute == true:
		set_volume(audio_bus_idx, 0.0)
	else:
		restore_previous_volume(audio_bus_idx)


## Proxy to [method AudioServer.is_bus_mute]
static func get_mute(audio_bus_idx: int) -> bool:
	return AudioServer.is_bus_mute(audio_bus_idx)


### TODO: all this below complexity is probably not necessary. Consider removing.
### Alternatively, consider making this the primary way to interact with audio buses
### and remove the the static signal hack above

static var _buses_cache: Dictionary[int, AudioBus] = {}

## Returns an abstraction class that wraps around an audio bus and handles volume
## and muted state in an OOP fashion. 
static func get_bus(audio_bus_idx: int) -> AudioBus:
	if audio_bus_idx not in _buses_cache:
		var audio_bus := AudioBus.new()
		audio_bus.index = audio_bus_idx
		_buses_cache[audio_bus_idx] = audio_bus
	return _buses_cache[audio_bus_idx]



class AudioBus:
## A utility class to handle volume and muting for one bus
##
## Do not instantiate this class directly, use [method VolumeUtils.get_bus]
## instead

	## The bux associated with this specific instance
	var index := 0: set = set_index

	## Emitted when the volume of this bus changes
	signal volume_changed(volume: float)
	
	## Emitted when the muted state of this bus changes
	signal mute_toggled(muted_state: bool)

	## The volume of this bus, in linear format (between [code]0.0[/code] and [code]1.0[/code]
	var volume := 0.0: set = set_volume, get = get_volume
	
	## The muted state for this bus.
	var is_mute := false: set = set_is_mute, get = get_is_mute

	var _update_main := false
	
	func _init() -> void:
		VolumeUtils.volume_changed.connect(func(idx: int, new_volume: float) -> void:
			if idx != index:
				return
			volume_changed.emit(new_volume)
		)
		VolumeUtils.mute_toggled.connect(func(idx: int, new_toggled: bool) -> void:
			if idx != index:
				return
			mute_toggled.emit(new_toggled)
		)

	func set_index(new_index: int) -> void:
		_update_main = false
		index = new_index
		volume = get_volume()
		is_mute = get_is_mute()
		_update_main = true

	func set_volume(new_volume: float) -> void:
		volume = new_volume
		if _update_main == true:
			VolumeUtils.set_volume(index, new_volume)

	func get_volume() -> float:
		return VolumeUtils.get_volume(index)

	func set_is_mute(new_mute: bool) -> void:
		is_mute = new_mute
		if _update_main == true:
			VolumeUtils.set_mute(index, new_mute)

	func get_is_mute() -> bool:
		return VolumeUtils.get_mute(index)
