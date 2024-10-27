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
	"Construction_Placeholder": Vector3i(1,0,14),
	"Wall_": Vector3i(1,0,0),
	"Wall_E_S_": Vector3i(1,0,1),
	"Wall_E_W_": Vector3i(1,1,1),
	"Wall_S_W_": Vector3i(1,2,1),
	"Wall_E_S_W_": Vector3i(1,6,1),
	"Wall_W_": Vector3i(1,7,1),
	"Wall_N_S_": Vector3i(1,0,2),
	"Wall_N_E_S_": Vector3i(1,3,2),
	"Wall_N_NE_E_S_W_NW_": Vector3i(1,9,2),
	"Wall_N_NE_E_SE_S_W_NW_": Vector3i(1,12,2),
	"Wall_N_NE_E_S_SW_W_NW_": Vector3i(1,15,2),
	"Wall_N_E_SE_S_SW_W_NW_": Vector3i(1,18,2),
	"Wall_N_E_": Vector3i(1,0,3),
	"Wall_N_W_": Vector3i(1,2,3),
	"Wall_N_": Vector3i(1,3,3),
	"Wall_E_": Vector3i(1,4,3),
	"Wall_N_S_W_": Vector3i(1,5,3),
	"Wall_N_E_SE_S_SW_W_": Vector3i(1,7,3),
	"Wall_N_NE_E_SE_S_W_": Vector3i(1,10,4),
	"Wall_S_": Vector3i(1,2,5),
	"Wall_N_E_S_W_": Vector3i(1,4,5),
	"Wall_N_NE_E_S_SW_W_": Vector3i(1,14,5),
	"Wall_N_NE_E_SE_S_SW_W_": Vector3i(1,18,5),
	"Wall_N_E_W_": Vector3i(1,2,6),
	"Wall_N_E_S_SW_W_": Vector3i(1,6,6),
	"Wall_E_SE_S_": Vector3i(1,0,7),
	"Wall_E_SE_S_SW_W_": Vector3i(1,1,7),
	"Wall_S_SW_W_": Vector3i(1,2,7),
	"Wall_N_NE_E_S_W_": Vector3i(1,8,7),
	"Wall_N_E_S_SW_W_NW_": Vector3i(1,12,7),
	"Wall_N_E_SE_S_W_NW_": Vector3i(1,16,7),
	"Wall_N_NE_E_SE_S_": Vector3i(1,0,8),
	"Wall_N_NE_E_SE_S_SW_W_NW_": Vector3i(1,1,8),
	"Wall_N_S_SW_W_NW_": Vector3i(1,2,8),
	"Wall_N_E_W_NW_": Vector3i(1,4,8),
	"Wall_N_NE_E_": Vector3i(1,0,9),
	"Wall_N_NE_E_W_NW_": Vector3i(1,1,9),
	"Wall_N_W_NW_": Vector3i(1,2,9),
	"Wall_E_S_SW_W_": Vector3i(1,4,9),
	"Wall_N_E_SE_S_W_": Vector3i(1,7,9),
	"Wall_N_E_S_W_NW_": Vector3i(1,10,9),
	"Wall_E_SE_S_W_": Vector3i(1,1,10),
	"Wall_N_NE_E_W_": Vector3i(1,5,11),
	"Wall_N_E_SE_S_": Vector3i(1,0,12),
	"Wall_N_S_SW_W_": Vector3i(1,3,12),
	"Wall_N_S_W_NW_": Vector3i(1,8,12),
	"Wall_N_NE_E_S_": Vector3i(1,9,12),

	"Door": Vector3i(2,0,0),
	"Door_1": Vector3i(2,0,1),
	"Door_2": Vector3i(2,0,2),
	"Door_3": Vector3i(2,0,3),
	"Door_4": Vector3i(2,0,4),
	"Door_5": Vector3i(2,0,5),
	"Door_6": Vector3i(2,1,0),
	"Door_7": Vector3i(2,1,1),
	"Door_8": Vector3i(2,1,2),
	"Door_9": Vector3i(2,1,3),
	"Door_10": Vector3i(2,1,4),
	"Door_11": Vector3i(2,1,5),

	"DockManagementDesk": Vector3i(3,0,0)
}

var job_applied_transforms = {}

var map: IslandMap

func initialize(m: IslandMap) -> void:
	map = m
	#TODO: connect to potential tile signals from the map
	map.on_tile_changed.connect(_on_tile_changed)
	map.on_tile_type_changed.connect(_on_tile_type_changed)
	map.on_fixture_created.connect(_on_fixture_created)
	map.on_fixture_changed.connect(_on_fixture_changed)
	map.on_fixture_destroyed.connect(_on_fixture_destroyed)

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
	var atlas_coords = _get_atlas_coords_for_fixture(f)
	
	GameManager.instance.world_tile_map.set_cell(1, Vector2(f.tile._position.x, f.tile._position.y), atlas_coords.x, Vector2i(atlas_coords.y, atlas_coords.z))


func _on_fixture_destroyed(f: Fixture) -> void:
	GameManager.instance.world_tile_map.set_cell(1, Vector2(f.tile._position.x, f.tile._position.y))


# Helper function to reduce redundancy
func is_relevant_fixture(tile):
	return tile != null and tile._fixture != null and (tile._fixture._fixture_type == "Wall" or tile._fixture._fixture_type == "Door")

# Combine conditions and reduce redundancy

func _on_fixture_changed(f: Fixture) -> void:
	var atlas_coords = _get_atlas_coords_for_fixture(f)
	var applied_transform = 0;
	if f._fixture_type == "Door":
		var n_tile = map.get_tile_at(f.tile._position.x, f.tile._position.y - 1)
		var s_tile = map.get_tile_at(f.tile._position.x, f.tile._position.y + 1)

		if is_relevant_fixture(n_tile) or is_relevant_fixture(s_tile):
			applied_transform += TileSetAtlasSource.TRANSFORM_TRANSPOSE
			applied_transform += TileSetAtlasSource.TRANSFORM_FLIP_H
	GameManager.instance.world_tile_map.set_cell(1, Vector2i(f.tile._position.x, f.tile._position.y), atlas_coords.x, Vector2i(atlas_coords.y, atlas_coords.z), applied_transform)


func _get_atlas_coords_for_fixture(f: Fixture, tile: Tile = null) -> Vector3i:
	var sprite_name = f._fixture_type

	if not f._links_to_neighbour:

		if f._fixture_type == "Door":
			var threshold = 1.0 / 12.0

			if f.fixture_parameters["open"] < threshold:
				sprite_name = "Door"
			elif f.fixture_parameters["open"] < threshold * 2:
				sprite_name = "Door_1"
			elif f.fixture_parameters["open"] < threshold * 3:
				sprite_name = "Door_2"
			elif f.fixture_parameters["open"] < threshold * 4:
				sprite_name = "Door_3"
			elif f.fixture_parameters["open"] < threshold * 5:
				sprite_name = "Door_4"
			elif f.fixture_parameters["open"] < threshold * 6:
				sprite_name = "Door_5"
			elif f.fixture_parameters["open"] < threshold * 7:
				sprite_name = "Door_6"
			elif f.fixture_parameters["open"] < threshold * 8:
				sprite_name = "Door_7"
			elif f.fixture_parameters["open"] < threshold * 9:
				sprite_name = "Door_8"
			elif f.fixture_parameters["open"] < threshold * 10:
				sprite_name = "Door_9"
			elif f.fixture_parameters["open"] < threshold * 11:
				sprite_name = "Door_10"
			else:
				sprite_name = "Door_11"

		return FIXTURE_ATLAS_COORDS[sprite_name]
	
	sprite_name = f._fixture_type + "_"

	var t: Tile
	var t1: Tile
	var t2: Tile

	t = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type):
		sprite_name += "N_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t2 = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1._job != null and t1._job is ConstructionJob and t1._job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2._job != null and t2._job is ConstructionJob and t2._job._fixture_type == f._fixture_type))):
		sprite_name += "NE_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type):
		sprite_name += "E_"

	t = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t2 = map.get_tile_at(f.tile._position.x + 1 if tile == null else tile._position.x + 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1._job != null and t1._job is ConstructionJob and t1._job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2._job != null and t2._job is ConstructionJob and t2._job._fixture_type == f._fixture_type))):
		sprite_name += "SE_"

	t = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type):
		sprite_name += "S_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y + 1 if tile == null else tile._position.y + 1)
	t2 = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1._job != null and t1._job is ConstructionJob and t1._job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2._job != null and t2._job is ConstructionJob and t2._job._fixture_type == f._fixture_type))):
		sprite_name += "SW_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type):
		sprite_name += "W_"

	t = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t1 = map.get_tile_at(f.tile._position.x if tile == null else tile._position.x, f.tile._position.y - 1 if tile == null else tile._position.y - 1)
	t2 = map.get_tile_at(f.tile._position.x - 1 if tile == null else tile._position.x - 1, f.tile._position.y if tile == null else tile._position.y)
	if ((t != null and (t._fixture != null and t._fixture._fixture_type == f._fixture_type) or (t._job != null and t._job is ConstructionJob and t._job._fixture_type == f._fixture_type)) and 
	(t1 != null and (t1._fixture != null and t1._fixture._fixture_type == f._fixture_type) or (t1._job != null and t1._job is ConstructionJob and t1._job._fixture_type == f._fixture_type)) and 
	(t2 != null and (t2._fixture != null and t2._fixture._fixture_type == f._fixture_type) or (t2._job != null and t2._job is ConstructionJob and t2._job._fixture_type == f._fixture_type))):
		sprite_name += "NW_"

	return FIXTURE_ATLAS_COORDS[sprite_name]
	
	
func has_relevant_fixture_or_job(tile):
	if tile != null:
		# Check fixture
		if tile._fixture != null and (tile._fixture._fixture_type == "Wall" or tile._fixture._fixture_type == "Door"):
			return true
		# Check fixture job as ConstructionJob
		if tile._job != null:
			var job = tile._job as ConstructionJob
			if job != null and (job._fixture_type == "Wall" or job._fixture_type == "Door"):
				return true
	return false	


func get_job_transform(j: Job) -> int:
	var applied_transform = 0

	if not j is ConstructionJob:
		return 0

	j = j as ConstructionJob

	if j._fixture_type == "Door":
		var n_tile = map.get_tile_at(j._tiles[0]._position.x, j._tiles[0]._position.y - 1)
		var s_tile = map.get_tile_at(j._tiles[0]._position.x, j._tiles[0]._position.y + 1)

		if has_relevant_fixture_or_job(n_tile) or has_relevant_fixture_or_job(s_tile):
			applied_transform += TileSetAtlasSource.TRANSFORM_TRANSPOSE
			applied_transform += TileSetAtlasSource.TRANSFORM_FLIP_H
	return applied_transform


func _on_job_created(j: Job) -> void:
	#TODO: Implement more than fixture jobs

	if j is ConstructionJob:
		var cj = j as ConstructionJob

		var atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[cj._fixture_type], cj._tiles[0])
		
		GameManager.instance.job_tile_map.set_cell(0, cj._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(cj))
		
		if not cj.job_started.is_connected(_on_job_started):
			cj.job_started.connect(_on_job_started)
		
		if cj._tiles.size() > 1:
			return
		
		var neighbour: Tile
		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x, cj._tiles[0]._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x + 1, cj._tiles[0]._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x + 1, cj._tiles[0]._position.y)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x + 1, cj._tiles[0]._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x, cj._tiles[0]._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x - 1, cj._tiles[0]._position.y + 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x - 1, cj._tiles[0]._position.y)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))

		neighbour = cj._tiles[0]._map.get_tile_at(cj._tiles[0]._position.x - 1, cj._tiles[0]._position.y - 1)
		if neighbour != null:
			if neighbour._fixture != null:
				neighbour._fixture.on_changed.emit(neighbour._fixture)
			elif neighbour._job != null && not neighbour._job._has_started:
				atlas_coord = _get_atlas_coords_for_fixture(GameManager.instance.map_controller.map._fixture_prototypes[neighbour._job._fixture_type], neighbour._job._tiles[0])
				GameManager.instance.job_tile_map.set_cell(0, neighbour._job._tiles[0]._position, atlas_coord.x, Vector2i(atlas_coord.y, atlas_coord.z), get_job_transform(neighbour._job))


		



func _on_job_started(j: Job) -> void:
	#TODO: implement more than fixture jobs
	GameManager.instance.job_tile_map.set_cell(0, j._tiles[0]._position)

	
