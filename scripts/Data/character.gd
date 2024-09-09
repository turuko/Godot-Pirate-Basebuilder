class_name Character extends RefCounted

signal on_changed(c: Character)

var x: float:
	get:
		return lerp(curr_tile._position.x, next_tile._position.x, movement_percentage)
	set(_value):
		return

var y: float:
	get:
		return lerp(curr_tile._position.y, next_tile._position.y, movement_percentage)
	set(_value):
		return

var curr_tile: Tile
var dest_tile: Tile
var next_tile: Tile

var path_astar: Queue

var movement_percentage: float

var speed: float = 5 #Tiles per second

var name: String

var _job: Job
var _can_work: bool = true

func _init(t: Tile, n: String):
	curr_tile = t
	dest_tile = t
	next_tile = t

	t._map.pathfinder.disable_tile(t)

	name = n


func update_handle_job(delta: float):
	if _job == null:
		_job = curr_tile._map.job_queue.dequeue()

		if _job != null:
			if not get_path_to_job():
				return

			_job.job_complete.connect(_on_job_ended)
			_job.job_cancel.connect(_on_job_ended)
			_job.job_started.connect(_on_job_started)

	if curr_tile == dest_tile:
		if _job != null:
			if not _can_work:
				#check if anything has changed

				if not curr_tile._map.characters.any(func(c): return c.curr_tile == _job._tile):
					_can_work = true
				return
			_job.work_job(delta)


func get_path_to_job() -> bool:
	var shortest_length := 10000000
	var dest = null
	for n in _job._tile.get_neighbours(true):
		if n == null:
			continue
		var path = curr_tile._map.pathfinder.get_path(curr_tile, n)
		if path.size() == 0:
			continue
		if path.size() < shortest_length:
			shortest_length = path.size()
			dest = path.peek_at(path.size() - 1)

	if dest == null:
		printerr("No path to job")
		abandon_job()
		return false
	else:
		if _job._tile == curr_tile:
			#We are standing on the work spot, so need to move before we can work the job
			if curr_tile._map.pathfinder.get_tile_active(curr_tile._map.get_tile_at(curr_tile._position.x, curr_tile._position.y - 1)):
				print("moving up")
				dest_tile = curr_tile._map.get_tile_at(curr_tile._position.x, curr_tile._position.y - 1)
			elif curr_tile._map.pathfinder.get_tile_active(curr_tile._map.get_tile_at(curr_tile._position.x + 1, curr_tile._position.y)):
				print("moving right")
				dest_tile = curr_tile._map.get_tile_at(curr_tile._position.x + 1, curr_tile._position.y)
			elif curr_tile._map.pathfinder.get_tile_active(curr_tile._map.get_tile_at(curr_tile._position.x, curr_tile._position.y + 1)):
				print("moving down")
				dest_tile = curr_tile._map.get_tile_at(curr_tile._position.x, curr_tile._position.y + 1)
			elif curr_tile._map.pathfinder.get_tile_active(curr_tile._map.get_tile_at(curr_tile._position.x - 1, curr_tile._position.y)):
				print("moving left")
				dest_tile = curr_tile._map.get_tile_at(curr_tile._position.x - 1, curr_tile._position.y)
		curr_tile._map.pathfinder.enable_tile(curr_tile)
		dest_tile = dest
		return true
	

func abandon_job() -> void:
	next_tile = curr_tile
	dest_tile = curr_tile

	path_astar = null

	curr_tile._map.job_queue.enqueue(_job)
	_job = null


func update_handle_movement(delta: float):

	if curr_tile == dest_tile:
		curr_tile._map.pathfinder.disable_tile(dest_tile)
		path_astar = null
		return

	if next_tile == null or next_tile == curr_tile:
		if path_astar == null:
			path_astar = curr_tile._map.pathfinder.get_path(curr_tile, dest_tile)
		if path_astar.size() == 0:
			printerr("No path from current tile to destination")
			abandon_job()
			return

		next_tile = path_astar.dequeue()

		if next_tile == curr_tile:
			printerr("next tile == current tile")
		

	var dist_total = sqrt(
		pow(curr_tile._position.x - next_tile._position.x, 2) + 
		pow(curr_tile._position.y - next_tile._position.y, 2))

	if next_tile.is_enterable() == Tile.Enterability.NEVER:
		printerr("Character tried to enter unwalkable tile")
		next_tile = null
		path_astar = null
		return
	elif next_tile.is_enterable() == Tile.Enterability.SOON:
		print("can soon enter tile")
		return

	var dist_this_frame = speed * delta

	var perc_this_frame = dist_this_frame / dist_total

	movement_percentage += perc_this_frame

	if movement_percentage >= 1:
		curr_tile = next_tile
		movement_percentage = 0;
	
	on_changed.emit(self)


func update(delta: float) -> void:
	update_handle_job(delta)
	update_handle_movement(delta)    
	

func set_destination(t: Tile) -> void:
	if curr_tile.is_neighbour(dest_tile, true):
		print("Destination tile is not adjecent to current tile")
	
	dest_tile = t


func _on_job_ended(j: Job) -> void:
	if j != _job:
		printerr("Character being told about job that is not his")
	
	_job = null


func _on_job_started(j: Job) -> void:
	for c in curr_tile._map.characters:
		if c.curr_tile == j._tile:
			_can_work = false


func save():

	var save_dict = {
		"curr_tile_x": curr_tile._position.x,
		"curr_tile_y": curr_tile._position.y,
		
		"dest_tile_x": dest_tile._position.x,
		"dest_tile_y": dest_tile._position.y,

		"next_tile_x": next_tile._position.x,
		"next_tile_y": next_tile._position.y,
	
		"movement_percentage": movement_percentage,
		"speed": speed,
		"name": name
	}

	if not _job == null:
		save_dict["job"] = _job.save()

	if not path_astar == null:
		var path_data = {
			"count": path_astar.count,
		}

		var path_values = []
		for t in path_astar.values:
			var tile = t as Tile
			var tile_data = {
				"x": tile._position.x,
				"y": tile._position.y,
			}
			path_values.push_back(tile_data)
		
		path_data["values"] = path_values

		save_dict["path_astar"] = path_data

	return save_dict


static func load(map: IslandMap, data: Dictionary) -> Character:
	var character_name = data["name"]
	var c_tile = map.get_tile_at(data["curr_tile_x"], data["curr_tile_y"])
	var character = Character.new(c_tile, character_name)
	character.dest_tile = map.get_tile_at(data["dest_tile_x"], data["dest_tile_y"])
	character.next_tile = map.get_tile_at(data["next_tile_x"], data["next_tile_y"])
	
	if data.has("path_astar"):
		character.path_astar = Queue.new()
		character.path_astar.count = data["path_astar"]["count"]
		for td in data["path_astar"]["values"]:
			var tile = map.get_tile_at(td["x"], td["y"])
			character.path_astar.enqueue(tile)
	
	character.movement_percentage = data["movement_percentage"]
	character.speed = data["speed"]

	if data.has("job"):
		var job 
		match (data["job"]["job_type"] as Job.JobType):
			Job.JobType.CONSTRUCTION: job = ConstructionJob.load(map, data["job"])
			Job.JobType.MISC: job = Job.load(map, data["job"])
		character._job = job
		character._job.job_complete.connect(character._on_job_ended)
		character._job.job_cancel.connect(character._on_job_ended)

	return character
