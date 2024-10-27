extends InspectorBase

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	super._process(_delta)
	if tile_under_mouse != null:
		if tile_under_mouse._item == null:
			visible = false
		else:
			visible = true
			text = "Item: " + tile_under_mouse._item._object_type + "(" + str(tile_under_mouse._item.stack_size) + ")"
