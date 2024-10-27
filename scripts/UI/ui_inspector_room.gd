extends InspectorBase

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	super._process(_delta)
	if tile_under_mouse != null:
		if tile_under_mouse._room == null or tile_under_mouse._room == tile_under_mouse._map.get_outside_room():
			visible = false
		elif tile_under_mouse._room != tile_under_mouse._map.get_outside_room():
			visible = true
			text = "Room: " + Room.pretty_print_type(tile_under_mouse._room.type)
