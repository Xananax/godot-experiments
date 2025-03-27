extends PanelContainer


###############################################################################
##
## Command line Arguments
##
###############################################################################


func _on_ready_read_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		echo_trace("requested to open file %s" % [ args[0] ])
		open_file(args[0])


###############################################################################
##
## Window Dragging
##
###############################################################################


var _is_dragging := false
var _drag_start_position := Vector2()


func _on_ready_setup_window() -> void:
	# makes godot bug and not show anything:
	# get_window().borderless = true 
	pass


func _on_mouse_input_event(event: InputEventMouseButton) -> void:
	_is_dragging = event.is_pressed()
	_drag_start_position = event.position


func _on_process_move_window() -> void:
	if _is_dragging:
		get_window().position += Vector2i(get_global_mouse_position() - _drag_start_position)


###############################################################################
##
## Opening Files
##
###############################################################################


@onready var _label_title: Label = %LabelTitle
var _metadata_file_path := ""


func open_file(path: String) -> void:
	var dirname = path.get_base_dir().trim_suffix("/")
	var filename = path.get_file()
	_text_edit.text = ""
	_label_title.text = ""
	_metadata_file_path = "%s/.metadata.%s.txt" % [dirname, filename]
	if FileAccess.file_exists(_metadata_file_path):
		var file := FileAccess.open(_metadata_file_path, FileAccess.READ)
		if file == null:
			_on_error("opening file '%s'" % [ _metadata_file_path ], FileAccess.get_open_error(), false)
			_metadata_file_path = ""
			return
		_text_edit.text = file.get_as_text()
		file.close()
	_label_title.text = path


###############################################################################
##
## File Dialog
##
###############################################################################

@onready var _button_open: Button = %ButtonOpen

func _on_ready_setup_file_dialog() -> void:
	var file_dialog: FileDialog = %FileDialog
	file_dialog.file_selected.connect(open_file)

	_button_open.pressed.connect(file_dialog.popup)


###############################################################################
##
## Saving
##
###############################################################################


var _save_timer := Timer.new()
var _has_unsaved_changes := false
var _save_timer_seconds := 0.5


func _on_ready_setup_save_timer() -> void:
	add_child(_save_timer)
	_save_timer.one_shot = true
	_save_timer.timeout.connect(func on_save_timeout() -> void:
		if _has_unsaved_changes == true:
			_save_file()
			_has_unsaved_changes = false
	)


func _save_file() -> void:
	if _metadata_file_path == "":
		return
	var file := FileAccess.open(_metadata_file_path, FileAccess.WRITE)
	if file == null:
		_on_error("opening file '%s'" % [ _metadata_file_path ], FileAccess.get_open_error(), false)
		return
	file.store_string(_text_edit.text)
	file.close()


###############################################################################
##
## Text Edit
##
###############################################################################


@onready var _text_edit: TextEdit = %TextEdit

var _lines_offset := 10
var _highlighter = NoteSyntaxHighlighter.new()

func _on_ready_setup_text_edit() -> void:
	_text_edit.syntax_highlighter = _highlighter
	_text_edit.text_changed.connect(func on_text_changed() -> void:
		_has_unsaved_changes = true
		_save_timer.start(_save_timer_seconds)
	)
	_text_edit.get_v_scroll_bar().value_changed.connect(func on_scroll_changed(_value: float) -> void:
		queue_redraw()
	)


func _on_redraw_draw_lines() -> void:
	var line_height := _text_edit.get_line_height()
	var offset := fmod(_text_edit.get_v_scroll_bar().ratio * _text_edit.get_v_scroll_bar().max_value, 1)
	for i in ceili(size.y / line_height):
		var y := line_height * (i + 1 - offset) + _lines_offset
		draw_line(Vector2(0, y), Vector2(size.x, y), _color_background_lines, 1)


class NoteSyntaxHighlighter extends SyntaxHighlighter:

	var color_hashtags := Color.AQUA
	var color_at_words := Color.FUCHSIA

	var regex := RegEx.create_from_string("(?<=\\s|^)(?<delimiter>@|#)(?<word>[a-zA-Z0-9_]\\w+)")

	func _get_line_syntax_highlighting(lineno: int) -> Dictionary:
		var dict := {}
		var default_color := get_text_edit().get_theme_color('font_color')
		var line := get_text_edit().get_line(lineno)
		
		var matches := regex.search_all(line)
		for i in range(matches.size()):
			var m := matches[i]
			var delimiter := m.get_string("delimiter")
			var color := color_hashtags if delimiter == "#" else color_at_words
			var start := m.get_start("delimiter")
			var end := m.get_end("word")
			dict[start] = { "color": color }
			dict[end] = { "color": default_color }
		return dict


###############################################################################
##
## Theme Handling
##
###############################################################################


@onready var _button_theme: Button = %ButtonTheme

var _color_hashtags := Color.AQUA
var _color_at_words := Color.FUCHSIA
var _color_background_lines := Color.hex(0x63AFFDFF)

var _icon_close: Texture2D
var _icon_open: Texture2D
var _icon_theme: Texture2D

var _dark_theme := preload("./theme/theme-dark.tres")
var _light_theme := preload("./theme/theme-light.tres")

var _current_theme: Theme = _dark_theme: set = _set_current_theme


func _set_current_theme(new_theme: Theme) -> void:
	const CUSTOM_TYPE = "custom_type"
	_current_theme = new_theme
	_text_edit.theme = new_theme
	_highlighter.clear_highlighting_cache()
	theme = _current_theme
	_button_theme.text = theme.get_type_variation_base(CUSTOM_TYPE)
	_color_hashtags = theme.get_color("accent_color", CUSTOM_TYPE) if theme.has_color("accent_color", CUSTOM_TYPE) else Color.RED
	_color_at_words = theme.get_color("accent_alt_color", CUSTOM_TYPE) if theme.has_color("accent_alt_color", CUSTOM_TYPE) else Color.RED
	_color_background_lines = theme.get_color("accent_muted_color", CUSTOM_TYPE) if theme.has_color("accent_muted_color", CUSTOM_TYPE) else Color.hex(0x63AFFDFF)
	_icon_close = theme.get_icon("close", CUSTOM_TYPE) if theme.has_icon("close", CUSTOM_TYPE) else null
	_icon_open = theme.get_icon("open", CUSTOM_TYPE) if theme.has_icon("open", CUSTOM_TYPE) else null
	_icon_theme = theme.get_icon("theme", CUSTOM_TYPE) if theme.has_icon("theme", CUSTOM_TYPE) else null
	_propagate_theme()

	_config.set_value("general", "theme", _current_theme.get_path())
	_save_config()


func _propagate_theme() -> void:
	_highlighter.color_hashtags = _color_hashtags
	_highlighter.color_at_words = _color_at_words
	_button_theme.icon = _icon_theme
	_button_open.icon = _icon_open
	_button_close.icon = _icon_close
	

func _on_ready_setup_theme() -> void:
	_button_theme.pressed.connect(func on_button_theme_pressed() -> void:
		_set_current_theme(_light_theme if _current_theme == _dark_theme else _dark_theme)
	)


###############################################################################
##
## Size/position Handling
##
###############################################################################


const _user_prefs_file_path := "user://preferences.cfg"
var _size := Vector2(800, 600)
var _position := Vector2(100, 100)
var _config := ConfigFile.new()


func _load_prefs() -> void:
	if _config.load(_user_prefs_file_path) != OK:
		return
	var window := get_window()
	window.size = _config.get_value("general", "size", window.size)
	window.position = _config.get_value("general", "position", window.position)
	_set_current_theme(load(_config.get_value("general", "theme", _dark_theme.get_path())))


func _save_on_exit() -> void:

	var window := get_window()
	_size = window.size
	_position = window.position

	_config.set_value("general", "size", _size)
	_config.set_value("general", "position", _position)
	_save_config()


func _save_config() -> void:
	_config.save(_user_prefs_file_path)


###############################################################################
##
## Utils
##
###############################################################################

enum LEVEL{
	TRACE,
	DEBUG,
	WARN,
	ERROR
}


func _on_error(message: String, error: Error, die: bool) -> void:
	var error_name := "Unknown Error"
	match error:
		7:
			error_name = "File Not Found: "
	push_error(error_name + message)
	if die == true:
		get_tree().quit(1)


func echo(level: LEVEL, message: String) -> void:
	var prefix := "?"
	match level:
		LEVEL.DEBUG:
			prefix = "🛈"
		LEVEL.WARN:
			prefix = "⚠"
		LEVEL.ERROR:
			prefix = "🛇"
	prints("[%s]" % [prefix], message)


func echo_trace(message: String) -> void: echo(LEVEL.DEBUG, message)
func echo_debug(message: String) -> void: echo(LEVEL.DEBUG, message)
func echo_warn(message: String) -> void:  echo(LEVEL.DEBUG, message)
func echo_error(message: String) -> void: echo(LEVEL.DEBUG, message)


###############################################################################
##
## Bootstrapping
##
###############################################################################


@onready var _button_close: Button = %ButtonClose


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	_button_close.pressed.connect(get_tree().quit)
	
	_on_ready_setup_file_dialog()
	_on_ready_setup_save_timer()
	_on_ready_setup_text_edit()
	_on_ready_setup_window()
	_on_ready_read_args()
	_on_ready_setup_theme()
	_load_prefs()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_input_event(event)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_on_mouse_input_event(event)


func _process(_delta: float) -> void:
	_on_process_move_window()


func _draw() -> void:
	_on_redraw_draw_lines()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_on_exit()
		_save_file()
		get_tree().quit()
