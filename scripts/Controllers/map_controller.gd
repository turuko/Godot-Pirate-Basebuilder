class_name MapController extends Node

var map: IslandMap


func _ready():
	map = IslandMap.new()
	map.generate()


func _process(delta):
	map.update(delta)


func get_tile_at_world_coord(coord: Vector2) -> Tile:
	var x = floori(coord.x)
	var y = floori(coord.y)

	return map.get_tile_at(x,y)
