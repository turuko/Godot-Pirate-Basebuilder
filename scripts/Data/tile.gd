class_name Tile extends RefCounted

signal tile_changed(t: Tile)
signal tile_type_changed(t: Tile)

enum TileType 
{
	WATER,
	SAND,
	GRASS,
	DARK_GRASS,
	ROCK,
	GREEN_ROCK,
	DARK_ROCK
}

var _position: Vector2i
var _type: TileType : set = _set_type

var _fixture: Fixture = null

#TODO: Replace this with a better solution that allows for checking if a tile has a job, but potentially also can check the type of job and execute logic based on that etc.
var fixture_job: Job 

var movement_cost: float:
	get:
		if _type == TileType.WATER:
			return 0
		
		if _fixture == null:
			return 1 #TODO: Different movement cost for different types of tiles, e.g. swamp is harder to move through than regular grass/sand etc
		
		return 1 * _fixture._movement_multiplier

var _map: IslandMap


func _init(m: IslandMap, p: Vector2i, t: TileType):
	_map = m
	_position = p
	_type = t


func _set_type(new_type: TileType):
	var old_type = _type
	_type = new_type

	if _type != old_type:
		tile_type_changed.emit(self)


func place_fixture(f_instance: Fixture):
	if f_instance == null:
		_fixture = null
		return true

	if _fixture != null:
		printerr("Trying to install fixture on a tile which already has one")
		return false

	_fixture = f_instance
	return true


func is_neighbour(t: Tile, diags: bool = false) -> bool:

	return (abs(_position.x - t._position.x) + abs(_position.y - t._position.y) == 1) or (diags && (abs(_position.x - t._position.x) == 1 && abs(_position.y - t._position.y) == 1))


func get_neighbours(diags: bool) -> Array[Tile]:
	var ns: Array[Tile] = []

	var n: Tile

	n = _map.get_tile_at(_position.x, _position.y - 1)
	ns.append(n)

	n = _map.get_tile_at(_position.x + 1, _position.y)
	ns.append(n)

	n = _map.get_tile_at(_position.x, _position.y + 1)
	ns.append(n)

	n = _map.get_tile_at(_position.x - 1, _position.y)
	ns.append(n)

	if diags:
		n = _map.get_tile_at(_position.x + 1, _position.y - 1)
		ns.append(n)

		n = _map.get_tile_at(_position.x + 1, _position.y + 1)
		ns.append(n)

		n = _map.get_tile_at(_position.x - 1, _position.y + 1)
		ns.append(n)

		n = _map.get_tile_at(_position.x - 1, _position.y - 1)
		ns.append(n)

	return ns

	
