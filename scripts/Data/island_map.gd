class_name IslandMap extends RefCounted

signal on_tile_changed(t: Tile)
signal on_tile_type_changed(t: Tile)
signal on_fixture_created(f: Fixture)
signal on_fixture_changed(f: Fixture)
signal on_character_created(c: Character)


var _width: int
var _height: int
var _elevation_seed: int
var _moisture_seed: int

var _tiles = [] #Array[Array[Tile]]

var _fixture_prototypes: Dictionary

var job_queue: JobQueue

var characters: Array[Character] = []
var fixtures: Array[Fixture] = []

var pathfinder: Path_AStar2

var map_generator_script = preload("res://scripts/Data/MapGenerator.cs")

func _init(width: int = 200, height: int = 200, e_seed: int = 98, m_seed: int = 198):
	
	job_queue = JobQueue.new()

	_width = width
	_height = height

	for x in range(_width):
		_tiles.append([])
		for y in range(_height):
			_tiles[x].append(Tile.new(self, Vector2i(x,y), Tile.TileType.WATER))

	_create_fixture_prototypes()

	_elevation_seed = e_seed
	_moisture_seed = m_seed


func generate():

	var map_generator = map_generator_script.new()
	map_generator.Init(_width, _height, _elevation_seed, _moisture_seed)
	map_generator.GenerateMap()


	for x in range(_width):
		for y in range(_height):
			var tile = Tile.new(self, Vector2i(x, y), _to_tile_type(map_generator.elevation[x][y], map_generator.moisture[x][y]))
			tile.tile_type_changed.connect(_on_tile_type_changed)
			tile.tile_changed.connect(_on_tile_changed)
			_tiles[x][y] = (tile)

	pathfinder = Path_AStar2.new(self)

	
func update(delta: float) -> void:

	for c in characters:
		c.update(delta)

	for f in fixtures:
		f.update(delta)


func create_character(t: Tile) -> Character:
	var c = Character.new(t, "Tester1")
	characters.append(c)
	on_character_created.emit(c)
	return c


func _create_fixture_prototypes():
	_fixture_prototypes = {}
	
	_fixture_prototypes["Wall"] = Fixture.create_prototype(
			"Wall",
			200,
			0,
			1,
			1,
			true
		)

	_fixture_prototypes["Construction_Placeholder"] = Fixture.create_prototype(
		"Construction_Placeholder",
		100,
		0,
		1,
		1,
		false
	)

	_fixture_prototypes["Door"] = Fixture.create_prototype(
		"Door",
		200,
		1.1,
		1,
		1,
		false
	)

	_fixture_prototypes["Door"].fixture_parameters["open"] = 0
	_fixture_prototypes["Door"].fixture_parameters["is_opening"] = 0
	_fixture_prototypes["Door"].update_actions.connect(FixtureActions.door_update_action)
	_fixture_prototypes["Door"].is_enterable = Callable(FixtureActions, "door_is_enterable")


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


func place_fixture(fixture_type: String, t: Tile) -> Fixture:
	if not _fixture_prototypes.has(fixture_type):
		printerr("No prototype for: " + fixture_type)
		return null
	
	var f = Fixture.place_instance(_fixture_prototypes[fixture_type], t)

	if f == null:
		return null

	fixtures.append(f)
	f.on_changed.connect(_on_fixture_changed)
	on_fixture_created.emit(f)

	if t.movement_cost == 0:
		pathfinder.disable_tile(t)
	else:
		pathfinder.enable_tile(t)
		pathfinder.set_tile_weight(t)

	return f


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

	save_dict["job_queue"] = job_queue.save()

	return save_dict
