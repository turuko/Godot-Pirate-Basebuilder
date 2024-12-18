class_name Fixture extends RefCounted

signal on_changed(f: Fixture)
var position_validation_func: Callable
var is_enterable: Callable

var tile: Tile
var _fixture_type: String

#Mulitplier. A value of 2 halves movement speed. 0 = impassable
var _movement_multiplier: float

var _room_blocker: bool

var _width:  int
var _height: int

var _max_health: int
var _health: float = 0

var _items_to_build: Dictionary
var _build_time: float

var _links_to_neighbour: bool

var fixture_parameters: Dictionary #string, Variant
signal update_actions(f: Fixture, delta_time: float)


func clone() -> Fixture:
	var f = Fixture.new()
	f._fixture_type = self._fixture_type
	f._movement_multiplier = self._movement_multiplier
	f._room_blocker = self._room_blocker
	f._width = self._width
	f._height = self._height
	f._max_health = self._max_health
	f._links_to_neighbour = self._links_to_neighbour
	f._items_to_build = self._items_to_build
	
	if self.is_enterable == null:
		print("no is_enterable function")
	
	f.position_validation_func = Callable(self.position_validation_func)
	f.is_enterable = Callable(self.is_enterable)
	
	if f.is_enterable == null:
		print("f has no is enterable")
	
	f.fixture_parameters = self.fixture_parameters.duplicate()

	for con in self.update_actions.get_connections():
		f.update_actions.connect(con.callable)

	return f


static func create_prototype(type: String, max_health: float, building_requirements: Array, move_cost: float = 1.0, w: int = 1, h: int = 1, ltn: bool = false, blocker: bool = false) -> Fixture:
	var f = Fixture.new()
	f._fixture_type = type
	f._movement_multiplier = move_cost
	f._room_blocker = blocker
	f._width = w
	f._height = h
	f._max_health = max_health
	f._links_to_neighbour = ltn
	f.position_validation_func = f.is_position_valid
	f._items_to_build = building_requirements[1]
	f._build_time = building_requirements[0]

	return f


static func place_instance(proto: Fixture, t: Tile) -> Fixture:
	if not proto.position_validation_func.call(t):
		printerr("position validity function returned false")
		return null

	var f = proto.clone()

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


func update(delta: float) -> void:
	update_actions.emit(self, delta)


func update_health(value: float):
	_health += value


func is_position_valid(t: Tile) -> bool:
	for x_off in range(t._position.x, t._position.x + _width):
		for y_off in range(t._position.y, t._position.y + _height):
			var t2 = t._map.get_tile_at(x_off, y_off)
			if t2._type == Tile.TileType.WATER:
				return false

			if t2._fixture != null:
				return false 

	#for c in t._map.characters:
	#	if c.curr_tile == t:
	#		return false

	return true


func save():
	var save_dict = {
		"x": tile._position.x,
		"y": tile._position.y,
		"fixture_type": _fixture_type,
		"movement_multiplier": _movement_multiplier
	}

	return save_dict
