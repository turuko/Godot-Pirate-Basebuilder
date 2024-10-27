class_name InspectorBase extends Label

var tile_under_mouse: Tile

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	tile_under_mouse = GameManager.instance.mouse_controller.get_tile_under_mouse()
