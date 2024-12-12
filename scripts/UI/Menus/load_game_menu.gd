extends PanelContainer

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var menu_controller = $".."

const save_game_icon_scene = preload("res://scenes/prefabs/ui/save_game_icon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	_get_saved_games()


func _get_saved_games():
	var dir = DirAccess.open("user://SaveGames")
	
	if dir == null:
		return
	
	for save in dir.get_files():
		var icon = save_game_icon_scene.instantiate()
		var time = FileAccess.get_modified_time(dir.get_current_dir() + "/" + save)
		icon.get_node("VBoxContainer/Label").text = save + "\n" + Time.get_date_string_from_unix_time(time)
		grid_container.add_child(icon)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	visible = false
	menu_controller.main_menu.visible = true
