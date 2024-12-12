extends Node

static var map_size: Vector2i = Vector2i.ZERO
static var map_seed: int = -1

static var display_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED:
	set(value):
		match value:
			DisplayServer.WINDOW_MODE_WINDOWED: # Windowed
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				display_mode = value
			DisplayServer.WINDOW_MODE_FULLSCREEN: #Borderless fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
				display_mode = value
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: #Fullscreen
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
				display_mode = value


static var resolution: Vector2i = Vector2i(1900, 1080)

#Volume in percent
static var main_volume: float = 100:
	set(value):
		var normalized = value / 100.0
		var db = _linear_to_db(normalized)
		AudioServer.set_bus_volume_db(0, db)
		main_volume = value


static var music_volume: float = 100:
	set(value):
		var normalized = value / 100.0
		var db = _linear_to_db(normalized)
		AudioServer.set_bus_volume_db(1, db)
		music_volume = value


static func _linear_to_db(value: float) -> float:
	if value == 0:
		return -80
	return 20 * (log(value) / log(10))


func _ready() -> void:
	if not FileAccess.file_exists("user://Config/settings.cfg"):
		save_settings()
	else:
		load_settings()


static func set_new_game_values(size: Vector2i, seed: int):
	map_size = size
	map_seed = seed


static func save_settings():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("Config"):
		dir.make_dir("Config")
	
	var settings: ConfigFile = ConfigFile.new()
	dir = DirAccess.open("user://Config")
	if dir.file_exists("settings.cfg"):
		var err = settings.load("user://Config/settings.cfg")
		if err != OK:
			return
	
	settings.set_value("Graphics", "display_mode", display_mode)
	settings.set_value("Graphics", "resolution", resolution)
	
	settings.set_value("Audio", "main_volume", main_volume)
	settings.set_value("Audio", "music_volume", music_volume)
	
	settings.save("user://Config/settings.cfg")


static func load_settings():
	if not FileAccess.file_exists("user://Config/settings.cfg"):
		return
	
	var settings = ConfigFile.new()
	
	var err = settings.load("user://Config/settings.cfg")
	if err != OK:
		return
		
	#Graphics settings
	display_mode = settings.get_value("Graphics", "display_mode")
	resolution = settings.get_value("Graphics", "resolution")
	
	#Audio settings
	main_volume = settings.get_value("Audio", "main_volume")
	music_volume = settings.get_value("Audio", "music_volume")
