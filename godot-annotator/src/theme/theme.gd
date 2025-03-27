@tool
extends ProgrammaticTheme

const UPDATE_ON_SAVE = true
const CUSTOM_TYPE = "custom_type"

var default_font_size = 16

var background_color: Color
var text_color: Color
var accent_color: Color
var accent_alt_color: Color
var accent_muted_color: Color

const IconClose = preload("./HugeiconsCancel01.svg")
const IconOpen = preload("./HugeiconsFile01.svg")
const IconDarkMode = preload("./HugeiconsGibbousMoon.svg")
const IconLightMode = preload("./HugeiconsSun02.svg")

func setup_light_theme() -> void:
	set_save_path("res://theme/theme-light.tres")
	background_color = Color.WHITE
	text_color = Color.BLACK
	accent_color = Color("#f684cf")
	accent_muted_color = accent_color.lightened(0.5)
	accent_alt_color = Color("#ffc52f")
	set_theme_generator(define_light_theme)


func setup_dark_theme() -> void:
	set_save_path("res://theme/theme-dark.tres")
	background_color = Color.BLACK
	text_color = Color.WHITE
	accent_color = Color.BLUE_VIOLET
	accent_muted_color = accent_color.darkened(0.5)
	accent_alt_color = Color("#ff00bb")
	set_theme_generator(define_dark_theme)


func define_light_theme() -> void:
	current_theme.set_icon("theme", CUSTOM_TYPE, IconLightMode)
	# Abusing properties to store strings
	current_theme.set_type_variation(CUSTOM_TYPE, "Light")
	define_theme()


func define_dark_theme() -> void:
	current_theme.set_icon("theme", CUSTOM_TYPE, IconDarkMode)
	# Abusing properties to store strings
	current_theme.set_type_variation(CUSTOM_TYPE, "Dark")
	define_theme()


func define_theme():

	define_default_font(preload("./BadComic-Regular.otf"))
	
	define_default_font_size(default_font_size)

	current_theme.set_color("accent_color", CUSTOM_TYPE, accent_color)
	current_theme.set_color("accent_alt_color", CUSTOM_TYPE, accent_alt_color)
	current_theme.set_color("accent_muted_color", CUSTOM_TYPE, accent_muted_color)
	current_theme.set_icon("close", CUSTOM_TYPE, IconClose)
	current_theme.set_icon("open", CUSTOM_TYPE, IconOpen)
	


	define_style("TextEdit", {
		font_color = text_color,
		caret_color = accent_color,
		normal = stylebox_flat({
			draw_center = false,
			border_ = border_width(1),
			border_color = accent_muted_color
		}),
		focus = stylebox_empty({}),
		read_only = stylebox_empty({})
	})

	define_style("Panel", {
		panel = stylebox_flat({
			bg_color = background_color,
			content_ = content_margins(5)
		})
	})
	
	define_style("PanelContainer", {
		panel = stylebox_flat({
			bg_color = background_color
		})
	})

	define_style("Label", {
		font_color = text_color
	})


	define_style("Button", {
		font_color = text_color,
		font_focus_color = text_color,
		font_hover_color = text_color,
		normal = stylebox_flat({
			bg_color = accent_color,
			content_ = content_margins(5, 3, 5, 3)
		}),
		hover = stylebox_flat({
			bg_color = accent_color.lightened(0.1),
			content_ = content_margins(5, 3, 5, 3)
		}),
		pressed = stylebox_flat({
			bg_color = accent_color.darkened(0.1),
			content_ = content_margins(5, 3, 5, 3)
		})
	})
	
	define_style("OptionButton", {
		normal = stylebox_flat({
			bg_color = accent_alt_color
		}),
		hover = stylebox_flat({
			bg_color = accent_alt_color.lightened(0.1)
		}),
		pressed = stylebox_flat({
			bg_color = accent_alt_color.darkened(0.1)
		})
	})
