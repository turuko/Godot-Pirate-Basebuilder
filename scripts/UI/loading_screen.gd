extends TextureRect

var scene_to_load = "res://scenes/game.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	ResourceLoader.load_threaded_request(scene_to_load)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(scene_to_load, progress)
	$VBoxContainer/ProgressBar.value = progress[0] * 100
	$VBoxContainer/ProgressLabel.text = str(int(progress[0] * 100)) + "%"
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(scene_to_load)
		get_tree().change_scene_to_packed(packed_scene)
