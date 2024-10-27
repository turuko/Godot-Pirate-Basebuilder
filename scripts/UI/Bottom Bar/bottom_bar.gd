extends MarginContainer

@onready var actions_menu = $"ActionsMenu"
@onready var build_menu = $"BuildMenu"
@onready var zone_menu = $"ZoneMenu"
# Called when the node enters the scene tree for the first time.
func _ready():
	var back_button = Button.new()
	back_button.text = "Back"

	var build_back = back_button.duplicate()
	build_back.pressed.connect(func(): 
		GameManager.instance.bmc.set_build_mode_fixture([null])
		close_menu(build_menu))
	build_menu.add_child(build_back)
	build_menu.move_child(build_back, 0)

	var zone_back = back_button.duplicate()
	zone_back.pressed.connect(func(): 
		GameManager.instance.bmc.set_build_mode_fixture([null])
		close_menu(zone_menu))
	zone_menu.add_child(zone_back)
	zone_menu.move_child(zone_back, 0)


func close_menu(menu):
	menu.visible = false
	actions_menu.visible = true


func open_menu(menu):
	menu.visible = true
	actions_menu.visible = false
