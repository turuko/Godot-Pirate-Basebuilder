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

static func pretty_print_tile_type(t: TileType) -> String:
	match t:
		TileType.WATER:
			return "Water"
		TileType.SAND:
			return "Sand"
		TileType.GRASS:
			return "Grass"
		TileType.DARK_GRASS:
			return "Dark Grass"
		TileType.ROCK:
			return "Stone"
		TileType.DARK_ROCK:
			return "Rock"
		TileType.GREEN_ROCK:
			return "Mossy Stone"
		_:
			return ""

enum Enterability
{
	YES,
	NEVER,
	SOON,
}

var _position: Vector2i
var _type: TileType : set = _set_type

var _fixture: Fixture = null
var _item: Item = null

var _room: Room

#TODO: Replace this with a better solution that allows for checking if a tile has a job, but potentially also can check the type of job and execute logic based on that etc.
var _job: Job 

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


func is_enterable() -> Enterability:
	if movement_cost == 0:
		return Enterability.NEVER
	
	if _fixture != null and _fixture.is_enterable != null:
		var enterable = _fixture.is_enterable.call(_fixture);
		return enterable as Enterability;

	return Enterability.YES


func place_fixture(f_instance: Fixture):

	if f_instance == null:
		var f = _fixture
		for x_off in range(_position.x, _position.x + _fixture._width):
			for y_off in range(_position.y, _position.y + _fixture._height):
				var t := _map.get_tile_at(x_off, y_off)
				t._fixture = null
		_map.destroy_fixture(f)
		return true

	if f_instance.position_validation_func.call(self) == false:
		printerr("Trying to install fixture in a tile that isn't valid")
		return false

	for x_off in range(_position.x, _position.x + f_instance._width):
		for y_off in range(_position.y, _position.y + f_instance._height):
			var t = _map.get_tile_at(x_off, y_off)
			t._fixture = f_instance

	return true


func place_item(i: Item):
	if i == null:
		_item = null
		return true
	
	if _item != null:
		if _item._object_type != i._object_type:
			printerr("Trying to add item on a tile which already has a different type")
			return false
		
		var num_to_change = i.stack_size if _item.stack_size + i.stack_size <= _item.max_stack_size else _item.max_stack_size - _item.stack_size
		
		_item.stack_size += num_to_change
		i.stack_size -= num_to_change
		_item.on_changed.emit(_item)
		return true

	_item = i
	_item.tile = self
	_item.on_changed.emit(_item)
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


func north() -> Tile:
	return _map.get_tile_at(_position.x, _position.y - 1)

func south() -> Tile:
	return _map.get_tile_at(_position.x, _position.y + 1)

func east() -> Tile:
	return _map.get_tile_at(_position.x + 1, _position.y)

func west() -> Tile:
	return _map.get_tile_at(_position.x - 1, _position.y)



func save():
	var save_dict = {
		"x": _position.x,
		"y": _position.y,
		"type": _type,
	}

	if _room != null:
		save_dict["room"] = _room.room_name

	return save_dict
