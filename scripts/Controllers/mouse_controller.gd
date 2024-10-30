class_name MouseController extends Node2D

@export var cursor_prefab: PackedScene

var last_frame_position: Vector2
var last_frame_viewport_position: Vector2
var curr_frame_tile_position: Vector2i

var curr_frame_pos: Vector2
var curr_viewport_frame_pos: Vector2

var _drag_start_position: Vector2
var _drag_preview_nodes = []
var _is_dragging = false
var _preview_hover: Sprite2D = Sprite2D.new()
var _highlighted_zone = {}
var _zones_last_frame: int = 0

var default_values = {}

#TODO: This does not feel like the correct place to have this dictionary. Where is more appropriate?
var _textures := {}
const preview_path = "res://assets/ui/previews"

func _ready():
	await get_tree().process_frame
	var temp = cursor_prefab.instantiate()
	default_values["texture"] = temp.texture
	default_values["modulate"] = temp.modulate
	temp.queue_free()
	if GameManager.instance == null:
		await GameManager.instance.ready

	var dir = DirAccess.open(preview_path)
	for key in GameManager.instance.map_controller.map._fixture_prototypes:
		if key == "Construction_Placeholder":
			continue
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			elif not dir.current_is_dir() and not file_name.begins_with(".") and not file_name.ends_with(".import") and file_name.split(".")[0] == key:
				_textures[key] = load(preview_path + "/" + file_name)
		dir.list_dir_end()

	for key in Zone.ZoneType:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			elif not dir.current_is_dir() and not file_name.begins_with(".") and not file_name.ends_with(".import") and file_name.split(".")[0] == key:
				_textures[key] = load(preview_path + "/" + file_name)
		dir.list_dir_end()
	
	add_child(_preview_hover)
	_preview_hover.centered = false

	SimplePool.reset()


func _unhandled_input(_event):

	_update_dragging()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	if not GameManager.instance.is_node_ready():
		return

	curr_viewport_frame_pos = get_viewport().get_mouse_position()
	curr_frame_pos = get_global_mouse_position()
	curr_frame_tile_position = GameManager.instance.world_tile_map.local_to_map(get_global_mouse_position())

	if GameManager.instance.bmc._build_mode != BuildModeController.BuildMode.NONE and !_is_dragging:
		_update_show_preview()
	else:
		_preview_hover.visible = false

	highlight_zones_under_mouse()
	
	_update_camera_movement()

	last_frame_viewport_position = curr_viewport_frame_pos
	last_frame_position = curr_frame_pos


func highlight_zones_under_mouse():
	var zones_under_mouse = GameManager.instance.map_controller.map.zones.filter(func(z): return z._tiles.has(get_tile_under_mouse()))

	for z in zones_under_mouse:
		if not _highlighted_zone.has(z) or _highlighted_zone[z] == false:
			GameManager.instance.zone_sprite_controller.highlight_zone(z)
			_highlighted_zone[z] = true
	
	for z in _highlighted_zone:
		if not zones_under_mouse.has(z) and _highlighted_zone[z]:
			GameManager.instance.zone_sprite_controller.unhighlight_zone(z)
			_highlighted_zone[z] = false


func get_tile_under_mouse() -> Tile:
	return GameManager.instance.map_controller.map.get_tile_at(curr_frame_tile_position.x, curr_frame_tile_position.y)


func _update_show_preview():
	_preview_hover.texture = _textures[GameManager.instance.bmc._build_mode_type]
	if GameManager.instance.bmc._build_mode == BuildModeController.BuildMode.FIXTURE:
		_preview_hover.modulate = Color(0.55, 1.0, 0.55, 0.35)
	else:
		_preview_hover.modulate = default_values["modulate"]
	
	if GameManager.instance.bmc._build_mode == BuildModeController.BuildMode.BULLDOZE:
		_preview_hover.texture = default_values["texture"]

	_preview_hover.position = curr_frame_tile_position * GameManager.UNIT_SIZE
	_preview_hover.visible = true

func _update_dragging():
	var offset := Vector2(1,1)
	if Input.is_action_just_pressed("left_mouse"):
		_is_dragging = true
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
		var bmc = GameManager.instance.bmc
		match bmc._build_mode:
			BuildModeController.BuildMode.FIXTURE:
				offset = Vector2(GameManager.instance.map_controller.map._fixture_prototypes[bmc._build_mode_type]._width, GameManager.instance.map_controller.map._fixture_prototypes[bmc._build_mode_type]._height)
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue
						
						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						if t != null and t._fixture == null and (t._job == null or not t._job is ConstructionJob):

							var node = SimplePool.spawn(cursor_prefab, Vector2(x,y) * GameManager.UNIT_SIZE, 0)
							node.texture = _textures[bmc._build_mode_type]
							node.modulate = Color(0.55, 1.0, 0.55, 0.35)
							if node.get_parent() == null:
								add_child(node)
							_drag_preview_nodes.append(node)

			BuildModeController.BuildMode.ZONE:
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue

						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						if t != null and t._fixture == null and t._job == null:
							var node = SimplePool.spawn(cursor_prefab, Vector2(x,y) * GameManager.UNIT_SIZE, 0)
							node.texture = _textures[bmc._build_mode_type]
							node.modulate = default_values["modulate"]
							if node.get_parent() == null:
								add_child(node)
							_drag_preview_nodes.append(node)
			
			BuildModeController.BuildMode.BULLDOZE:
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue

						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						var node = SimplePool.spawn(cursor_prefab, Vector2(x,y) * GameManager.UNIT_SIZE, 0)
						node.texture = default_values["texture"]
						node.modulate = default_values["modulate"]
						if node.get_parent() == null:
							add_child(node)
						_drag_preview_nodes.append(node)


	if Input.is_action_just_released("left_mouse"):
		match GameManager.instance.bmc._build_mode:
			BuildModeController.BuildMode.FIXTURE:
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue

						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						if t != null and (t._job == null or not t._job is ConstructionJob):
							GameManager.instance.bmc.build([t])
			BuildModeController.BuildMode.ZONE:
				var tiles : Array[Tile] = []
				
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue
						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						tiles.append(t)
				#Tell BuildModeController to construct zone
				GameManager.instance.bmc.build(tiles)
			BuildModeController.BuildMode.BULLDOZE:
				for x in range(start_x, end_x+1, offset.x):
					for y in range(start_y, end_y+1, offset.y):
						if x < 0 or x >= GameManager.instance.map_controller.map._width or  y < 0 or y >= GameManager.instance.map_controller.map._height:
							continue

						var t = GameManager.instance.map_controller.map.get_tile_at(x,y)
						GameManager.instance.bmc.build([t])

		_is_dragging = false


func _update_camera_movement():
	if Input.is_action_pressed("middle_mouse"):
		var diff = last_frame_viewport_position - curr_viewport_frame_pos
		(get_viewport().get_camera_2d() as CameraController).drag(diff)
