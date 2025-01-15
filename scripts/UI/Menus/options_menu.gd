class_name OptionsMenu extends PanelContainer

@onready var menu_controller = $".."
@onready var main_volume_label = $HBox/HBox2/MainAudio/VBoxContainer/MainVolumeLabel
@onready var music_volume_label = $HBox/HBox2/Music/VBoxContainer/MusicVolumeLabel
@onready var display_mode_selector = $HBox/HBox/DisplayMode/DisplayModeSelector
@onready var resolution_selector = $HBox/HBox/Resolution/ResolutionSelector
@onready var main_volume: HSlider = $HBox/HBox2/MainAudio/VBoxContainer/MainVolume
@onready var music_volume: HSlider = $HBox/HBox2/Music/VBoxContainer/MusicVolume
@onready var back_button: Button = $Button

var set_back_con: bool = false
var back_con: Callable

const DISPLAY_MODES: Dictionary = {
	DisplayServer.WINDOW_MODE_WINDOWED : 0,
	DisplayServer.WINDOW_MODE_FULLSCREEN: 1,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: 2,
}

const RESOLUTION_DICTIONARY: Dictionary = {
	"1280 x 720"  : Vector2i(1280, 720),
	"1600 x 900"  : Vector2i(1600, 900),
	"1920 x 1080" : Vector2i(1920, 1080),
	"3840 x 2160" : Vector2i(3840, 2160),
}

func _ready():
	display_mode_selector.selected = DISPLAY_MODES[DisplayServer.window_get_mode()]
	add_resolution_options()
	set_current_resolution()
	main_volume.value = Globals.main_volume
	music_volume.value = Globals.music_volume
	
	if set_back_con:
		for con in back_button.pressed.get_connections():
			back_button.pressed.disconnect(con.callable)
		back_button.pressed.connect(back_con)


func set_back_connection(c: Callable):
	set_back_con = true
	back_con = c


func add_resolution_options():
	for r in RESOLUTION_DICTIONARY:
		resolution_selector.add_item(r)


func _on_back_button_pressed():
	visible = false
	menu_controller.main_menu.visible = true
	Globals.save_settings()


func _on_main_volume_value_changed(value):
	main_volume_label.text = str(value) + "%"
	Globals.main_volume = value


func _on_music_volume_value_changed(value):
	music_volume_label.text = str(value) + "%"
	Globals.music_volume = value


func _on_resolution_selector_item_selected(index):
	DisplayServer.window_set_size(RESOLUTION_DICTIONARY.values()[index])
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)
	Globals.resolution = RESOLUTION_DICTIONARY.values()[index]


func set_current_resolution():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		resolution_selector.selected = RESOLUTION_DICTIONARY.values().find(DisplayServer.screen_get_size())
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		resolution_selector.selected = RESOLUTION_DICTIONARY.values().find(DisplayServer.window_get_size())

func _on_display_mode_selector_item_selected(index):
	match index:
		0: # Windowed
			Globals.display_mode = DisplayServer.WINDOW_MODE_WINDOWED
			resolution_selector.disabled = false
			set_current_resolution()
		1: #Borderless fullscreen
			Globals.display_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
			resolution_selector.disabled = true
			set_current_resolution()
		2: #Fullscreen
			Globals.display_mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			resolution_selector.disabled = true
			set_current_resolution()
