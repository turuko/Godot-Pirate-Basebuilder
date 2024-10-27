extends InspectorBase

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	super._process(_delta)
	if tile_under_mouse != null:
		if tile_under_mouse._fixture == null:
			visible = false
		else:
			visible = true
			text = "Fixture: " + tile_under_mouse._fixture._fixture_type
