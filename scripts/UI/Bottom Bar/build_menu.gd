extends HBoxContainer

var build_button_prefab = preload("res://scenes/prefabs/ui/build_button.tscn")
const preview_path = "res://assets/ui/previews"
# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(preview_path)
	for key in GameManager.instance.map_controller.map._fixture_prototypes:
		if key == "Construction_Placeholder":
			continue
		var button = build_button_prefab.instantiate() as UIButton
		button.args = [key]
		button.text = key

		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			elif not dir.current_is_dir() and not file_name.begins_with(".") and not file_name.ends_with(".import") and file_name.split(".")[0] == key:
				button.icon = load(preview_path + "/" + file_name)
		dir.list_dir_end()
		add_child(button)