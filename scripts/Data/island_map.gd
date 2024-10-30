class_name IslandMap extends RefCounted

signal on_tile_changed(t: Tile)
signal on_tile_type_changed(t: Tile)
signal on_fixture_created(f: Fixture)
signal on_fixture_changed(f: Fixture)
signal on_fixture_destroyed(f: Fixture)
signal on_character_created(c: Character)
signal on_item_created(i: Item)
signal on_item_destroyed(i: Item)
signal on_zone_created(z: Zone)


var _width: int
var _height: int
var _elevation_seed: int
var _moisture_seed: int

var _tiles = [] #Array[Array[Tile]]

var _fixture_prototypes: Dictionary
var _item_prototypes: Dictionary

var job_queue: JobQueue

var characters: Array[Character] = []
var fixtures: Array[Fixture] = []
var item_manager: ItemManager
var rooms: Array[Room] = []
var zones: Array[Zone] = []

var pathfinder: Path_AStar2
var lua: LuaAPI

var map_generator_script = preload("res://scripts/Data/MapGenerator.cs")

func _init(width: int = 200, height: int = 200, e_seed: int = 98, m_seed: int = 198):

	lua = LuaAPI.new()
	lua.bind_libraries(["base", "table", "math", "string"])
	if lua.do_string(FileAccess.get_file_as_string("res://scripts/Data/Objects/fixture_actions.lua")) != null:
		printerr("Error loading lua")
	
	job_queue = JobQueue.new()
	#job_queue.job_dequeued.connect(JobActions.haul_dequeued)

	_width = width
	_height = height

	for x in range(_width):
		_tiles.append([])
		for y in range(_height):
			_tiles[x].append(Tile.new(self, Vector2i(x,y), Tile.TileType.WATER))

	_create_fixture_prototypes()
	_create_item_prototypes()

	_elevation_seed = e_seed
	_moisture_seed = m_seed


func generate():

	var map_generator = map_generator_script.new()
	map_generator.Init(_width, _height, _elevation_seed, _moisture_seed)
	map_generator.GenerateMap()

	rooms.append(Room.new("Outside"))



	for x in range(_width):
		for y in range(_height):
			var tile = Tile.new(self, Vector2i(x, y), _to_tile_type(map_generator.elevation[x][y], map_generator.moisture[x][y]))
			tile.tile_type_changed.connect(_on_tile_type_changed)
			tile.tile_changed.connect(_on_tile_changed)
			_tiles[x][y] = (tile)
			_tiles[x][y]._room = get_outside_room()

	pathfinder = Path_AStar2.new(self)

	create_character(get_tile_at(_width / 2, _height / 2))
	create_character(get_tile_at(_width / 2, _height / 2+1))
	create_character(get_tile_at(_width / 2, _height / 2+2))
	create_character(get_tile_at(_width / 2, _height / 2+3))
	create_item_in_map("Logs", get_tile_at(_width / 2 + 1, _height / 2))
	create_item_in_map("Logs", get_tile_at(_width / 2 + 10, _height / 2), 10)
	
	create_item_in_map("Logs", get_tile_at(_width / 2 + 5, _height / 2 + 5), 40)
	create_item_in_map("Logs", get_tile_at(_width / 2 + 3, _height / 2 + 5), 40)
	create_item_in_map("Logs", get_tile_at(_width / 2 + 4, _height / 2 + 5), 40)
	create_item_in_map("Logs", get_tile_at(_width / 2 + 2, _height / 2 + 5), 40)


func update(delta: float) -> void:

	for c in characters:
		c.update(delta)

	for f in fixtures:
		f.update(delta)


func create_character(t: Tile) -> Character:
	var c = Character.new(t, "Tester1")
	characters.append(c)
	on_character_created.emit(c)
	c.created_item.connect(func(i): on_item_created.emit(i))
	return c


func add_character(c: Character):
	characters.append(c)
	if c._item != null:
		on_item_created.emit(c._item)
	c.created_item.connect(func(i): on_item_created.emit(i))


func _create_fixture_prototypes():
	_fixture_prototypes = {}
	
	_fixture_prototypes["Wall"] = Fixture.create_prototype(
			"Wall",
			200,
			[1,{"Logs" = 5}],
			0,
			1,
			1,
			true,
			true
		)
	
	_fixture_prototypes["DockManagementDesk"] = Fixture.create_prototype(
		"DockManagementDesk",
		150,
		[5,{"Logs" = 30}],
		0,
		2,
		1,
	)

	_fixture_prototypes["Construction_Placeholder"] = Fixture.create_prototype(
		"Construction_Placeholder",
		100,
		[0,{}],
		0,
		1,
		1,
		false
	)

	_fixture_prototypes["Door"] = Fixture.create_prototype(
		"Door",
		200,
		[1.5, {"Logs" = 10}],
		5,
		1,
		1,
		false,
		true
	)

	_fixture_prototypes["Door"].fixture_parameters["open"] = 0
	_fixture_prototypes["Door"].fixture_parameters["is_opening"] = 0
	_fixture_prototypes["Door"].update_actions.connect(lua.pull_variant("DoorUpdateAction"))

	var door_is_enterable = lua.pull_variant("DoorIsEnterable")
	_fixture_prototypes["Door"].is_enterable = door_is_enterable


func get_fixture_build_requirements(fixture_type: String) -> Array:
	return [_fixture_prototypes[fixture_type]._build_time, _fixture_prototypes[fixture_type]._items_to_build.duplicate(true)]


func _create_item_prototypes():
	_item_prototypes = {}

	_item_prototypes["Logs"] = Item.create_prototype(
		"Logs",
		40
	)

	item_manager = ItemManager.new(_item_prototypes.keys())


func get_outside_room() -> Room:
	return rooms[0]


func add_room(r: Room):
	rooms.append(r)
	on_zone_created.connect(func(_z): r.update_room_type())


func delete_room(r: Room):
	if r == get_outside_room():
		printerr("Deleting outside \"room\" ")
		return
	r.unassign_all_tiles()
	rooms.erase(r)


func add_zone(z: Zone):
	zones.append(z)
	on_zone_created.emit(z)


func delete_zone(z: Zone):
	zones.erase(z)


func _to_tile_type(elevation: float, moisture: float) -> Tile.TileType:

	if elevation < 0.1:
		return Tile.TileType.WATER
	if elevation < 0.13:
		return Tile.TileType.SAND

	if elevation > 0.4:
		if moisture < 0.15:
			return Tile.TileType.DARK_ROCK
		if moisture < 0.35:
			return Tile.TileType.ROCK
		return Tile.TileType.GREEN_ROCK

	if moisture < 0.35:
		return Tile.TileType.SAND
	if moisture < 0.55:
		return Tile.TileType.GRASS
	return Tile.TileType.DARK_GRASS


func _on_tile_type_changed(t: Tile) -> void:
	on_tile_type_changed.emit(t)
	if t.movement_cost == 0:
		pathfinder.disable_tile(t)


func _on_tile_changed(t: Tile) -> void:
	on_tile_changed.emit(t)
	if t.movement_cost == 0:
		pathfinder.disable_tile(t)


func get_tile_at(x: int, y: int) -> Tile:

	if x >= _width or x < 0 or y >= _height or y < 0:
		return null

	return _tiles[x][y]


func get_character(char_name: String) -> Character:
	for c in characters:
		if c.name == char_name:
			return c
	return null


func place_fixture(fixture_type: String, t: Tile, do_flood_fill: bool = true) -> Fixture:
	if not _fixture_prototypes.has(fixture_type):
		printerr("No prototype for: " + fixture_type)
		return null
	
	var f = Fixture.place_instance(_fixture_prototypes[fixture_type], t)
	
	if f == null:
		return null

	fixtures.append(f)

	if f._room_blocker == true and do_flood_fill:
		Room.room_flood_fill(f)

	f.on_changed.connect(_on_fixture_changed)
	on_fixture_created.emit(f)

	if t.movement_cost == 0:
		pathfinder.disable_tile(t)
	else:
		pathfinder.enable_tile(t)
		pathfinder.set_tile_weight(t)

	if f.tile._room != null and f.tile._room != get_outside_room():
		f.tile._room.add_fixture(f)

	return f


func destroy_fixture(f: Fixture):
	fixtures.erase(f)
	on_fixture_destroyed.emit(f)
	
	if f._links_to_neighbour:
		for n in f.tile.get_neighbours(true):
			if n._fixture != null and n._fixture._fixture_type == f._fixture_type:
				n._fixture.on_changed.emit(n._fixture)


func create_item_in_map(item_type: String, t: Tile, amount = null) -> Item:
	if not _item_prototypes.has(item_type):
		printerr("No prototype for: " + item_type)
		return null
	
	var stack_size = amount if amount != null else _item_prototypes[item_type].stack_size

	var i = Item.create_instance(_item_prototypes[item_type], stack_size)

	if item_manager.place_item(i, t) == false:
		return null
	
	on_item_created.emit(i)
	return i


func place_item(item: Item, t: Tile) -> Item:
	if item_manager.place_item(item, t) == false:
		return null

	return item


func is_fixture_placement_valid(fixture_type: String, t: Tile) -> bool:
	return _fixture_prototypes[fixture_type].position_validation_func.call(t)


func _on_fixture_changed(f: Fixture) -> void:
	on_fixture_changed.emit(f)


func save() -> Dictionary:
	var save_dict = {
		"width": _width,
		"height": _height,
	}

	var tiles_save_data = []
	for x in range(_width):
		for y in range(_height):
			tiles_save_data.append(_tiles[x][y].save())
	
	save_dict["tiles"] = tiles_save_data

	var fixtures_save_data = []
	for f in fixtures:
		fixtures_save_data.append(f.save())

	save_dict["fixtures"] = fixtures_save_data

	var characters_save_data = []
	for c in characters:
		characters_save_data.append(c.save())

	save_dict["characters"] = characters_save_data

	var rooms_save_data = []
	for r in rooms:
		rooms_save_data.append(r.save())

	save_dict["rooms"] = rooms_save_data

	save_dict["item_manager"] = item_manager.save()

	save_dict["rooms"] = rooms_save_data

	save_dict["job_queue"] = job_queue.save()

	return save_dict
