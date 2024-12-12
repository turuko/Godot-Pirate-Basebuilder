extends Control

@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
@onready var main_menu = $MainMenu
@onready var new_game_menu = $NewGameMenu
@onready var options_menu = $OptionsMenu
@onready var load_game_menu: PanelContainer = $LoadGameMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("Title Scaling")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		animation_player.stop()
