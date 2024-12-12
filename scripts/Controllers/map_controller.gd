class_name MapController extends Node

var map: IslandMap

static var _load := false
static var save_data

func _ready():
	EventBus.new_world_button_pressed.connect(new_world_button)

	if _load:
		_load = false
		create_world_from_save()
	else:
		if Globals.map_seed == -1 and Globals.map_size == Vector2i.ZERO:
			create_new_world()
		else:
			create_new_world(Globals.map_size, Globals.map_seed)


func _process(delta):
	map.update(delta)


func get_tile_at_world_coord(coord: Vector2) -> Tile:
	var x = floori(coord.x)
	var y = floori(coord.y)

	return map.get_tile_at(x,y)


func new_world_button(_args):
	get_tree().reload_current_scene()


func load_world(_save_data):
	_load = true
	save_data = _save_data
	get_tree().reload_current_scene()


func create_new_world(size: Vector2i = Vector2i(200, 200), seed: int = 0):
	var e_seed = seed ^ 0xDEADBEEF
	var m_seed = ~seed
	
	if seed == 0:
		map = IslandMap.new(size.x, size.y)
	else:	
		map = IslandMap.new(size.x, size.y, e_seed, m_seed)
	map.generate()


func create_world_from_save():
	map = IslandMap.new(save_data["width"], save_data["height"])

	var tiles: Array = save_data["tiles"]

	var rooms_data: Array = save_data["rooms"]
	for r in rooms_data:
		var room = Room.load(map, r)
		map.rooms.append(room)

	for t in tiles:
		map._tiles[t["x"]][t["y"]]._type = t["type"]
		if t.has("room"):
			for r in map.rooms:
				if r.room_name == t["room"]:
					map._tiles[t["x"]][t["y"]]._room = r

	map.pathfinder = Path_AStar2.new(map)
	
	map.job_queue.queue.count = save_data["job_queue"]["queue"]["count"]
	
	var jobs_data: Array = save_data["job_queue"]["queue"]["values"];
	var jobs := []
	for j in jobs_data:
		var job
		match (j["job_type"] as Job.JobType):
			Job.JobType.CONSTRUCTION: 
				job = ConstructionJob.load(map,j)
			Job.JobType.MISC: 
				job = Job.load(map, j)
		jobs.append(job)
	map.job_queue.queue.values = jobs

	var characters_data: Array = save_data["characters"]
	for c in characters_data:
		var character = Character.load(map, c)

		map.add_character(character)

	var fixtures_data: Array = save_data["fixtures"]
	for f in fixtures_data:
		var fix : Fixture = map.place_fixture(f["fixture_type"], map.get_tile_at(f["x"], f["y"]), false)
		fix._movement_multiplier = f["movement_multiplier"]

	var items_data = save_data["item_manager"]["items"]
	for k in items_data.keys():
		var values = []
		for i in items_data[k]:
			values.append(Item.load(map, i))
		map.item_manager.all_items[k] = values

	
