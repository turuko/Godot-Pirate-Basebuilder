extends InspectorBase

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	super._process(_delta)
	if tile_under_mouse != null:
		text = "Tile Type: " + Tile.pretty_print_tile_type(tile_under_mouse._type)
