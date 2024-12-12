extends VBoxContainer

@onready var new_game_button : Button = $"NewGameButton"
@onready var load_game_button : Button = $"LoadGameButton"
@onready var options_button : Button = $"OptionsButton"
@onready var exit_button : Button = $"ExitButton"
@onready var menu_controller = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_exit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _on_new_game_button_pressed():
	visible = false
	menu_controller.new_game_menu.visible = true


func _on_options_button_pressed():
	visible = false
	menu_controller.options_menu.visible = true


func _on_load_game_button_pressed() -> void:
	visible = false
	menu_controller.load_game_menu.visible = true
