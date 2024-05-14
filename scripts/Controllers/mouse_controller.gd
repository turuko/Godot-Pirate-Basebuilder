class_name MouseController extends Node2D

@export var cursor_prefab: PackedScene

var last_frame_position: Vector2
var last_frame_viewport_position: Vector2
var last_frame_tile_position: Vector2i

var curr_frame_pos: Vector2
var curr_viewport_frame_pos: Vector2

var _drag_start_position: Vector2
var _drag_preview_nodes = []

func _unhandled_input(_event):
	_update_dragging()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	curr_viewport_frame_pos = get_viewport().get_mouse_position()
	curr_frame_pos = get_global_mouse_position()
	
	_update_camera_movement()

	last_frame_viewport_position = curr_viewport_frame_pos
	last_frame_position = curr_frame_pos
	last_frame_tile_position = GameManager.world_tile_map.local_to_map(get_global_mouse_position())


func _update_dragging():

	if Input.is_action_just_pressed("left_mouse"):
		_drag_start_position = curr_frame_pos

	var start_x = floori(_drag_start_position.x / GameManager.UNIT_SIZE) 
	var end_x = floori(curr_frame_pos.x / GameManager.UNIT_SIZE)

	var start_y = floori(_drag_start_position.y / GameManager.UNIT_SIZE)
	var end_y = floori(curr_frame_pos.y / GameManager.UNIT_SIZE)

	if end_x < start_x:
			var temp = end_x
			end_x = start_x
			start_x = temp

	if end_y < start_y:
		var temp = end_y
		end_y = start_y
		start_y = temp

	while _drag_preview_nodes.size() > 0:
		var node = _drag_preview_nodes[0]
		_drag_preview_nodes.remove_at(0)
		SimplePool.despawn(node)

	if Input.is_action_pressed("left_mouse"):
		for x in range(start_x, end_x+1):
			for y in range(start_y, end_y+1):
				if x < 0 or x >= GameManager.map_controller.map._width or  y < 0 or y >= GameManager.map_controller.map._height:
					continue
				
				var t = GameManager.map_controller.map.get_tile_at(x,y)
				if t != null:
					var node = SimplePool.spawn(cursor_prefab, Vector2(x,y) * GameManager.UNIT_SIZE, 0)
					if node.get_parent() == null:
						add_child(node)
					_drag_preview_nodes.append(node)

	

	if Input.is_action_just_released("left_mouse"):
		for x in range(start_x, end_x+1):
			for y in range(start_y, end_y+1):
				if x < 0 or x >= GameManager.map_controller.map._width or  y < 0 or y >= GameManager.map_controller.map._height:
					continue

				var t = GameManager.map_controller.map.get_tile_at(x,y)
				if t != null:
					GameManager.bmc.build(t)


func _update_camera_movement():
	if Input.is_action_pressed("middle_mouse"):
		var diff = last_frame_viewport_position - curr_viewport_frame_pos
		(get_viewport().get_camera_2d() as CameraController).drag(diff)
