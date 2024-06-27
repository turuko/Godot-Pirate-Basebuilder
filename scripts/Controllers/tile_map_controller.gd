class_name TileMapController extends Node

# This could probably stay as it is, but would make sense to read this in from a config file
# Would allow for modding in new tiles, potentially
# Potentially LUA could be used to setup these constant tables
const TERRAIN_ATLAS_COORDS = {
	Tile.TileType.WATER: Vector2i(0,0),
	Tile.TileType.SAND: Vector2i(1,0),
	Tile.TileType.GRASS: Vector2i(2,0), #GRASS
	Tile.TileType.DARK_GRASS: Vector2i(0,1), #DARK_GRASS
	Tile.TileType.ROCK: Vector2i(1,1), #ROCK
	Tile.TileType.GREEN_ROCK: Vector2i(2,1), #GREEN_ROCK
	Tile.TileType.DARK_ROCK: Vector2i(0,2), #DARK_ROCK
}

const FIXTURE_ATLAS_COORDS = {
	"Construction_Placeholder": Vector2i(0,14),
	"Wall_": Vector2i(0,0),
	"Wall_E_S_": Vector2i(0,1),
	"Wall_E_W_": Vector2i(1,1),
	"Wall_S_W_": Vector2i(2,1),
	"Wall_E_S_W_": Vector2i(6,1),
	"Wall_W_": Vector2i(7,1),
	"Wall_N_S_": Vector2i(0,2),
	"Wall_N_E_S_": Vector2i(3,2),
	"Wall_N_NE_E_S_W_NW_": Vector2i(9,2),
	"Wall_N_NE_E_SE_S_W_NW_": Vector2i(12,2),
	"Wall_N_NE_E_S_SW_W_NW_": Vector2i(15,2),
	"Wall_N_E_SE_S_SW_W_NW_": Vector2i(18,2),
	"Wall_N_E_": Vector2i(0,3),
	"Wall_N_W_": Vector2i(2,3),
	"Wall_N_": Vector2i(3,3),
	"Wall_E_": Vector2i(4,3),
	"Wall_N_S_W_": Vector2i(5,3),
	"Wall_N_E_SE_S_SW_W_": Vector2i(7,3),
	"Wall_N_NE_E_SE_S_W_": Vector2i(10,4),
	"Wall_S_": Vector2i(2,5),
	"Wall_N_E_S_W_": Vector2i(4,5),
	"Wall_N_NE_E_S_SW_W_": Vector2i(14,5),
	"Wall_N_NE_E_SE_S_SW_W_": Vector2i(18,5),
	"Wall_N_E_W_": Vector2i(2,6),
	"Wall_N_E_S_SW_W_": Vector2i(6,6),
	"Wall_E_SE_S_": Vector2i(0,7),
	"Wall_E_SE_S_SW_W_": Vector2i(1,7),
	"Wall_S_SW_W_": Vector2i(2,7),
	"Wall_N_NE_E_S_W_": Vector2i(8,7),
	"Wall_N_E_S_SW_W_NW_": Vector2i(12,7),
	"Wall_N_E_SE_S_W_NW_": Vector2i(16,7),
	"Wall_N_NE_E_SE_S_": Vector2i(0,8),
	"Wall_N_NE_E_SE_S_SW_W_NW_": Vector2i(1,8),
	"Wall_N_S_SW_W_NW_": Vector2i(2,8),
	"Wall_N_E_W_NW_": Vector2i(4,8),
	"Wall_N_NE_E_": Vector2i(0,9),
	"Wall_N_NE_E_W_NW_": Vector2i(1,9),
	"Wall_N_W_NW_": Vector2i(2,9),
	"Wall_E_S_SW_W_": Vector2i(4,9),
	"Wall_N_E_SE_S_W_": Vector2i(7,9),
	"Wall_N_E_S_W_NW_": Vector2i(10,9),
	"Wall_E_SE_S_W_": Vector2i(1,10),
	"Wall_N_NE_E_W_": Vector2i(5,11),
	"Wall_N_E_SE_S_": Vector2i(0,12),
	"Wall_N_S_SW_W_": Vector2i(3,12),
	"Wall_N_S_W_NW_": Vector2i(8,12),
	"Wall_N_NE_E_S_": Vector2i(9,12),
}

var map: IslandMap

func initialize(m: IslandMap) -> void:
	map = m
	#TODO: connect to potential tile signals from the map
	map.on_tile_changed.connect(_on_tile_changed)
	map.on_tile_type_changed.connect(_on_tile_type_changed)
	map.on_fixture_created.connect(_on_fixture_created)
	map.on_fixture_changed.connect(_on_fixture_changed)

	map.job_queue.job_enqueued.connect(_on_job_created)

	for x in range(map._width):
		for y in range(map._height):
			var t: Tile = map.get_tile_at(x,y)
			_on_tile_type_changed(t)

	for j in map.job_queue.queue.values:
		_on_job_created(j)

	for c in map.characters:
		if c._job == null:
			continue
		_on_job_created(c._job)

	for f in map.fixtures:
		_on_fixture_created(f)


func _on_tile_type_changed(t: Tile) -> void:
	GameManager.instance.world_tile_map.set_cell(0, Vector2(t._position.x, t._position.y), 0, TERRAIN_ATLAS_COORDS[t._type])

func _on_tile_changed(_t: Tile) -> void:
	pass


func _on_fixture_created(f: Fixture) -> void:
	GameManager.instance.world_tile_map.set_cell(0, Vector2(f.tile._position.x, f.tile._position.y), 1, _get_atlas_coords_for_fixture(f))


func _on_fixture_changed(f: Fixture) -> void:
	GameManager.instance.world_tile_map.set_cell(0, Vector2i(f.tile._position.x, f.tile._position.y), 1, _get_atlas_coords_for_fixture(f))


func _get_atlas_coords_for_fixture(f: Fixture, tile: Tile = null) -> Vector2i:
	if not f._links_to_neighbour:
		return FIXTURE_ATLAS_COORDS[f._fixture_type]

	var sprite_name: String = f._fixture_type + "_"

	var t: Tile
	var t1: Tile
	var t2: Tile

	t = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type):
		sprite_name += "N_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t2 = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1.fixture_job != null and t1.fixture_job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2.fixture_job != null and t2.fixture_job._fixture_type == f._fixture_type))):
		sprite_name += "NE_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type):
		sprite_name += "E_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t2 = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1.fixture_job != null and t1.fixture_job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2.fixture_job != null and t2.fixture_job._fixture_type == f._fixture_type))):
		sprite_name += "SE_"

	t = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type):
		sprite_name += "S_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t2 = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1.fixture_job != null and t1.fixture_job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2.fixture_job != null and t2.fixture_job._fixture_type == f._fixture_type))):
		sprite_name += "SW_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type):
		sprite_name += "W_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t2 = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t.fixture_job != null and t.fixture_job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1.fixture_job != null and t1.fixture_job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2.fixture_job != null and t2.fixture_job._fixture_type == f._fixture_type))):
		sprite_name += "NW_"

	return FIXTURE_ATLAS_COORDS[sprite_name]
	
	
func _on_job_created(j: Job) -> void:
	#TODO: Implement more than fixture jobs

	if j is ConstructionJob:
		var cj = j as ConstructionJob

		var atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[cj._fixture_type], cj._tile)
		GameManager.instance.job_tile_map.set_cell(0, cj._tile._position, 1, atlas_coord)

		var neighbour: Tile
		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x, cj._tile._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x + 1, cj._tile._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x + 1, cj._tile._position.y)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x + 1, cj._tile._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x, cj._tile._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x - 1, cj._tile._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x - 1, cj._tile._position.y)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)

		neighbour = cj._tile._map.get_tile_at(cj._tile._position.x - 1, cj._tile._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null and neighbour._fixture._fixture_type == cj._fixture_type:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour.fixture_job != null && neighbour.fixture_job._fixture_type == cj._fixture_type:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour.fixture_job._fixture_type], neighbour.fixture_job._tile)
				GameManager.instance.job_tile_map.set_cell(0, neighbour.fixture_job._tile._position, 1, atlas_coord)


		if not cj.job_complete.is_connected(_on_job_ended):
			cj.job_complete.connect(_on_job_ended)
		if not cj.job_cancel.is_connected(_on_job_ended):
			cj.job_cancel.connect(_on_job_ended)



func _on_job_ended(j: Job) -> void:
	#TODO: implement more than fixture jobs
	GameManager.instance.job_tile_map.set_cell(0, j._tile._position)

	
