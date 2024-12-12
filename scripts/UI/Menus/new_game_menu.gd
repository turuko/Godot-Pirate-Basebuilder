extends PanelContainer

@onready var start_button = $VBoxContainer/StartNewGameButton
@onready var map_size_button = $VBoxContainer/HBoxContainer/MapSizeSelector
@onready var map_seed_input = $"VBoxContainer/HBoxContainer2/Map Seed"
@onready var menu_controller = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_new_game_button_pressed():
	var size = map_size_button.get_selected_id()
	var seed = _convert_string_to_number(map_seed_input.text)
	
	var map_size: Vector2i = Vector2i.ZERO
	if size == 0:
		map_size = Vector2i(100,100)
	elif size == 1:
		map_size = Vector2i(200,200)
	elif size == 2:
		map_size = Vector2i(300,300)
	#setup map with correct parameters
	Globals.set_new_game_values(map_size, seed)
	get_tree().change_scene_to_packed(load("res://scenes/loading_screen.tscn"))


func _convert_string_to_number(input: String) -> int:
	var total = 0
	
	for c in input:
		if c.is_valid_int():
			total += c.to_int()
		elif c.unicode_at(0) >= "A".unicode_at(0) and c.unicode_at(0) <= "Z".unicode_at(0) or ( c.unicode_at(0) >= "a".unicode_at(0) and c.unicode_at(0) <= "z".unicode_at(0)):
			total += c.to_upper().unicode_at(0) - "A".unicode_at(0) + 1
	
	return total


func _on_back_button_pressed():
	visible = false
	menu_controller.main_menu.visible = true
