extends PanelContainer

const main_menu = preload("res://scenes/main_menu.tscn")
const options_menu_scene = preload("res://scenes/prefabs/ui/options_menu.tscn")
const load_menu_scene = preload("res://scenes/prefabs/ui/load_game_menu.tscn")

@onready var save_game_button: Button = $VBoxContainer/SaveGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_menu_button: Button = $VBoxContainer/ExitMenuButton
@onready var exit_game_button: Button = $VBoxContainer/ExitGameButton
@onready var return_to_game: Button = $VBoxContainer/ReturnToGame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return_to_game.pressed.connect(func(): visible = false)
	
	exit_game_button.pressed.connect(func():
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit())
		
	exit_menu_button.pressed.connect(func():
		get_tree().change_scene_to_packed(main_menu))
		
	options_button.pressed.connect(func():
		var menu = options_menu_scene.instantiate() as OptionsMenu
		
		menu.set_back_connection(func(): menu.visible = false)
		add_child(menu)
		menu.visible = true
		)
	
	load_game_button.pressed.connect(func(): 
		var menu = load_menu_scene.instantiate() as LoadMenu
		
		menu.set_back_connection(func(): menu.visible = false)
		add_child(menu)
		menu.visible = true
		)




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Esc"):
		if visible == false:
			visible = true
			#TODO: Pause game
