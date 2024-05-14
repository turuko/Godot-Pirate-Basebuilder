class_name Fixture extends RefCounted

signal on_changed(f: Fixture)
var position_validation_func: Callable

var tile: Tile
var _fixture_type: String

#Mulitplier. A value of 2 halves movement speed. 0 = impassable
var _movement_multiplier: float

var _width:  int
var _height: int

var _links_to_neighbour: bool


static func create_prototype(type: String, move_cost: float = 1, w: int = 1, h: int = 1, ltn: bool = false) -> Fixture:
	var f = Fixture.new()
	f._fixture_type = type
	f._movement_multiplier = move_cost
	f._width = w
	f._height = h
	f._links_to_neighbour = ltn
	f.position_validation_func = f.is_position_valid

	return f


static func place_instance(proto: Fixture, t: Tile) -> Fixture:
	if not proto.position_validation_func.call(t):
		printerr("position validity function returned false")
		return null

	var f = Fixture.new()
	f._fixture_type = proto._fixture_type
	f._movement_multiplier = proto._movement_multiplier
	f._width = proto._width
	f._height = proto._height
	f._links_to_neighbour = proto._links_to_neighbour
	f.position_validation_func = proto.position_validation_func

	f.tile = t

	if not t.place_fixture(f):
		return null

	if f._links_to_neighbour:
		var neighbour: Tile

		neighbour = t._map.get_tile_at(f.tile._position.x, f.tile._position.y - 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x + 1, f.tile._position.y - 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x + 1, f.tile._position.y)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x + 1, f.tile._position.y + 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x, f.tile._position.y + 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x - 1, f.tile._position.y + 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x - 1, f.tile._position.y)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

		neighbour = t._map.get_tile_at(f.tile._position.x - 1, f.tile._position.y - 1)
		if neighbour != null and neighbour._fixture != null and neighbour._fixture._fixture_type == f._fixture_type:
			neighbour._fixture.on_changed.emit(neighbour._fixture)

	return f


func is_position_valid(t: Tile) -> bool:
	
	if t._type == Tile.TileType.WATER:
		return false

	if t._fixture != null:
		return false


	return true