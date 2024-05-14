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

var _map #Array[Array[Tile]]

var _fixture_prototypes: Dictionary

var job_queue: JobQueue

var characters: Array[Character] = []

var pathfinder: Path_AStar2

var map_generator_script = preload("res://scripts/Data/MapGenerator.cs")

func _init(width: int = 400, height: int = 400, e_seed: int = 98, m_seed: int = 198):
	
	job_queue = JobQueue.new()

	_width = width
	_height = height
	_elevation_seed = e_seed
	_moisture_seed = m_seed


func generate():

	var map_generator = map_generator_script.new()
	map_generator.Init(_width, _height, _elevation_seed, _moisture_seed)
	map_generator.GenerateMap()

	_map = []

	for x in range(_width):
		_map.append([])
		for y in range(_height):
			var tile = Tile.new(self, Vector2i(x, y), _to_tile_type(map_generator.elevation[x][y], map_generator.moisture[x][y]))
			tile.tile_type_changed.connect(_on_tile_type_changed)
			tile.tile_changed.connect(_on_tile_changed)
			_map[x].append(tile)

	_create_fixture_prototypes()
	pathfinder = Path_AStar2.new(self)

	
func update(delta: float) -> void:

	for c in characters:
		c.update(delta)


func create_character(t: Tile) -> Character:
	var c = Character.new(t, "Tester")
	characters.append(c)
	on_character_created.emit(c)
	return c


func _create_fixture_prototypes():
	_fixture_prototypes = {}
	
	_fixture_prototypes["Wall"] = Fixture.create_prototype(
			"Wall",
			0,
			1,
			1,
			true
		)


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

	return _map[x][y]


func place_fixture(fixture_type: String, t: Tile):
	if not _fixture_prototypes.has(fixture_type):
		printerr("No prototype for: " + fixture_type)
		return
	
	var f = Fixture.place_instance(_fixture_prototypes[fixture_type], t)

	if f == null:
		return
	f.on_changed.connect(_on_fixture_changed)
	on_fixture_created.emit(f)

	if t.movement_cost == 0:
		pathfinder.disable_tile(t)


func is_fixture_placement_valid(fixture_type: String, t: Tile) -> bool:
	return _fixture_prototypes[fixture_type].position_validation_func.call(t)


func _on_fixture_changed(f: Fixture) -> void:
	on_fixture_changed.emit(f)


func save_map():
	pass