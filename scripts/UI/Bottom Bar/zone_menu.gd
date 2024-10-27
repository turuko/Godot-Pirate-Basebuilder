extends HBoxContainer

var build_button_prefab = preload("res://scenes/prefabs/ui/build_button.tscn")
const preview_path = "res://assets/ui/previews"
# Called when the node enters the scene tree for the first time.
func _ready():
	for key in Zone.ZoneType:
		var type = key as Zone.ZoneType
		var button = UIButton.new()
		button.signal_name = "zone_button_pressed"
		button.args = [key]
		button.text = Zone.pretty_print_type(type)

		
		add_child(button)