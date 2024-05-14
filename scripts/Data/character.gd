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

	if curr_tile == dest_tile:
		if _job != null:
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
