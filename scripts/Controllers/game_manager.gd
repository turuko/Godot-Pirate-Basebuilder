extends Node

var world_tile_map_scene = preload("res://scenes/world_tile_map.tscn")
var world_tile_map: TileMap

var job_tile_map_scene = preload("res://scenes/jobs_tile_map.tscn")
var job_tile_map: TileMap

var map_controller: MapController
var bmc: BuildModeController
var tile_sprite_controller: TileMapController

const UNIT_SIZE: int = 32

# Called when the node enters the scene tree for the first time.
func _ready():
	world_tile_map = world_tile_map_scene.instantiate() as TileMap
	job_tile_map = job_tile_map_scene.instantiate() as TileMap
	var game_root = get_node("/root/Game")
	game_root.add_child(world_tile_map)
	game_root.add_child(job_tile_map)

	map_controller = game_root.get_node("Controllers/MapController") as MapController
	bmc = game_root.get_node("Controllers/BuildModeController") as BuildModeController
	tile_sprite_controller = game_root.get_node("Controllers/TileMapController") as TileMapController

	

	if not map_controller.is_node_ready():
		await map_controller.ready

	tile_sprite_controller.initialize(map_controller.map)

	var camera = get_viewport().get_camera_2d() as CameraController
	camera.limit_bottom = floori((map_controller.map._height * UNIT_SIZE))
	camera.limit_top = 0
	camera.limit_right = floori((map_controller.map._width * UNIT_SIZE)) 
	camera.limit_left = 0

	var real_value = (-1.2698e-7)*pow(map_controller.map._width,3) + 0.000104127*pow(map_controller.map._width,2) + -0.0273968*(map_controller.map._width) + 2.6254
	var max_zoom_value = _round_to_nearest_tenth(real_value)
	camera.max_zoom = Vector2(max(max_zoom_value, 0.1), max(max_zoom_value,0.1))
	print("Map size: " + str(map_controller.map._width) + ", Max zoom: " + str(camera.max_zoom) + ", real: " + str(real_value)) 

	camera.position = Vector2(map_controller.map._width * UNIT_SIZE / 2.0, map_controller.map._height * UNIT_SIZE / 2.0)


func _round_to_nearest_tenth(n: float) -> float:
	# Multiply the number by 10 to shift the digit you want to round to the units place
	var shifted_number = n * 10

	# Round the shifted number to the nearest whole number
	var rounded_number = round(shifted_number)

	# Divide the rounded number by 10 to shift the digit back to its original place
	var result = rounded_number / 10

	return result

