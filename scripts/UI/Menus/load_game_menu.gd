class_name LoadMenu extends PanelContainer

@onready var list_container: VBoxContainer = $HBoxContainer/ScrollContainer/GridContainer
@onready var menu_controller = $".."
@onready var back_button: Button = $BackButton
@onready var save_icon: TextureRect = $HBoxContainer/VBoxContainer/TextureRect
@onready var save_label: Label = $HBoxContainer/VBoxContainer/Label

const save_game_icon_scene = preload("res://scenes/prefabs/ui/save_game_icon.tscn")

var selected_save: String

var set_back_con: bool = false
var back_con: Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	_get_saved_games()
	
	if set_back_con:
		for con in back_button.pressed.get_connections():
			back_button.pressed.disconnect(con.callable)
		back_button.pressed.connect(back_con)


func set_back_connection(c: Callable):
	set_back_con = true
	back_con = c


func _get_saved_games():
	var dir = DirAccess.open("user://SaveGames")
	
	if dir == null:
		return
	
	for save in dir.get_files():
		var name = save.substr(0, save.length() - 4)
		var item: Button = Button.new()
		var time = FileAccess.get_modified_time(dir.get_current_dir() + "/" + save)
		var zip := ZIPReader.new()
		zip.open("user://SaveGames/" + save)
		var image: Image = Image.new()
		image.load_png_from_buffer(zip.read_file("image.png"))
		zip.close()
		item.text = name
		var e = StyleBoxEmpty.new()
		item.add_theme_stylebox_override("normal", e)
		item.add_theme_stylebox_override("hover", e)
		item.add_theme_stylebox_override("pressed", e)
		item.add_theme_stylebox_override("focus", e)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.pressed.connect(func(): 
			save_icon.texture = ImageTexture.create_from_image(image)
			save_label.text = name + "\n" + Time.get_datetime_string_from_unix_time(time)
			selected_save = name)
		list_container.add_child(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	visible = false
	menu_controller.main_menu.visible = true


func _on_load_button_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://scenes/loading_screen.tscn"))
	#SaveLoadController.load_game([selected_save])
