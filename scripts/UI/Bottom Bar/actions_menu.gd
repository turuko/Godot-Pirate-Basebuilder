extends Node

@onready var build_menu_button: Button = $"BuildMenuButton"
@onready var zone_menu_button: Button = $"ZoneMenuButton"
@onready var bottom_bar = $".."


func _ready():
	build_menu_button.pressed.connect(func(): bottom_bar.open_menu(bottom_bar.build_menu))
	zone_menu_button.pressed.connect(func(): bottom_bar.open_menu(bottom_bar.zone_menu))


