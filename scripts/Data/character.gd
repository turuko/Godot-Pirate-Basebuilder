class_name Character extends RefCounted

signal on_changed(c: Character)
signal created_item(i: Item)

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
var closest_job_tile: Tile = null
var _item: Item = null
var _carrying_capacity: int = 5
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
			_job.job_complete.connect(_on_job_ended)
			_job.job_cancel.connect(_on_job_ended)
			_job.job_started.connect(_on_job_started)

	if _job is ConstructionJob:
		handle_construction_job(delta)
	elif _job is HaulJob:
		handle_haul_job(delta)

func handle_haul_job(_delta: float):
	var hj := _job as HaulJob
	if _item != null and _item._object_type == hj.item_type_to_haul and (_item.stack_size == min(_carrying_capacity, hj._job_time) or not get_path_to_nearest_item(hj.item_type_to_haul, curr_tile == hj._tiles[0], false)):
		
		#if get_path_to_nearest_item(hj.item_type_to_haul) == false:
		#	printerr("No items of the type to haul??")
		#	abandon_job()
		#	return
		
		if get_path_to_job() == false:
			return
		if curr_tile == dest_tile:
			hj.work_job(_item.stack_size)
			curr_tile._map.item_manager.place_item(_item, curr_tile)
			_item = null
	else:
		if not get_path_to_nearest_item(hj.item_type_to_haul, curr_tile == hj._tiles[0], false):
			abandon_job()
			return
		
		curr_tile._map.pathfinder.enable_tile(curr_tile)

		if curr_tile == dest_tile:
			var amount_to_pickup = min(_carrying_capacity, hj._job_time)
			if _item != null:
				amount_to_pickup -= _item.stack_size
			
			if amount_to_pickup <= 0:
				return
			
			var map = curr_tile._map
			var result = map.item_manager.take_item(curr_tile, amount_to_pickup)
			if _item != null:
				if result[0]:
					if result[1] is int:
						_item.stack_size += result[1]
						_item.on_changed.emit(_item)
					elif result[1] is Item:
						_item.stack_size += result[1].stack_size
						_item.on_changed.emit(_item)
			else:
				if result[0]:
					if result[1] is int:
						_create_item(hj.item_type_to_haul, result[1])
					elif result[1] is Item:
						_item = result[1]
						_item.character = self


func handle_construction_job(delta: float):
	var cj = _job as ConstructionJob
	if not cj._has_required_items:
		#get first item requirement
		var item_type: String = ""
		for type in cj._required_items.keys():
			if not cj.has_enough_of_item(type):
				item_type = type
				break
		#Check if character is holding item of correct type

		if _item != null and _item._object_type == item_type and (_item.stack_size == min(_carrying_capacity, cj._required_items[item_type]) or not get_path_to_nearest_item(item_type)):
			#Get path to job
			if get_path_to_job(true) == false:
				return
			
			if curr_tile == dest_tile:
				if _job != null:
					cj.add_item(_item)
					print("Item is null: ", _item == null)
					return
		else:
			#Character is not holding item of correct type or can hold more of it, so find and go to nearest item of required type
			if not get_path_to_nearest_item(item_type):
				abandon_job()
				return

			curr_tile._map.pathfinder.enable_tile(curr_tile)
				
			if curr_tile == dest_tile:
				var amount_to_pickup = min(_carrying_capacity, cj._required_items[item_type])
				if _item != null:
					amount_to_pickup -= _item.stack_size
				
				if amount_to_pickup <= 0:
					return

				var map = curr_tile._map
				var result = map.item_manager.take_item(curr_tile, amount_to_pickup)
				if _item != null:
					if result[0]:
						if result[1] is int:
							_item.stack_size += result[1]
							_item.on_changed.emit(_item)
						elif result[1] is Item:
							_item.stack_size += result[1].stack_size
							_item.on_changed.emit(_item)
				else:
					print("No item at pickup: ", _item == null)
					if result[0]:
						print("can pickup")
						if result[1] is int:
							_create_item(item_type, result[1])
						elif result[1] is Item:
							_item = result[1]
							_item.character = self
	else:
		if get_path_to_job(true) == false:
				return
		if curr_tile == dest_tile:
			if _job != null:
				if not _can_work:
					#check if anything has changed

					if not curr_tile._map.characters.any(func(c): return _job._tiles.has(c.curr_tile)):
						_can_work = true
					return
				if not cj._has_required_items:
					if _item == null:
						printerr("Should character not have an item of some kind here?!")
						return
					cj.add_item(_item)
					print("Item is null: ", _item == null)
					return

				cj.work_job(delta)

func _create_item(item_type: String, amount: int):
	_item = Item.create_instance(curr_tile._map._item_prototypes[item_type], amount)
	_item.character = self
	created_item.emit(_item)


func get_path_to_nearest_item(item_type: String, exclude_current_tile: bool = false, include_items_in_stockpiles: bool = true) -> bool:
	var shortest_length = 10000000
	var dest = null
	var map = curr_tile._map
	for i in map.item_manager.all_items[item_type] as Array[Item]:
		if not include_items_in_stockpiles:
			if map.item_manager.is_item_in_stockpile(i):
				continue
		if exclude_current_tile:
			if i.tile == curr_tile:
				continue
		var path = map.pathfinder.get_path(curr_tile, i.tile)
		if path.size() == 0:
			continue
		if path.size() < shortest_length:
			shortest_length = path.size()
			dest = i.tile
	
	if dest == null:
		return false
	else:
		dest_tile = dest
		return true

func get_path_to_job(stop_before_job_tile: bool = false) -> bool:
	var shortest_length := 10000000
	var dest = null

	var shortest_length_job = 100000000
	for t in _job._tiles:
		var path = curr_tile._map.pathfinder.get_path(curr_tile, t)
		if path.size() == 0:
			continue
		if path.size() < shortest_length_job:
			shortest_length_job = path.size()
			closest_job_tile = t

	if stop_before_job_tile == true:
		for n in closest_job_tile.get_neighbours(true):
			if n == null:
				continue
			var path = curr_tile._map.pathfinder.get_path(curr_tile, n)
			if path.size() == 0:
				continue
			if path.size() < shortest_length:
				shortest_length = path.size()
				dest = path.peek_at(path.size() - 1)
	else:
		dest = closest_job_tile

	if dest == null:
		printerr("No path to job")
		abandon_job()
		return false
	else:
		if stop_before_job_tile:
			if closest_job_tile == curr_tile:
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

	_job.job_complete.disconnect(_on_job_ended)
	_job.job_cancel.disconnect(_on_job_ended)
	_job.job_started.disconnect(_on_job_started)
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
		return

	var dist_this_frame = speed / next_tile.movement_cost * delta

	var perc_this_frame = dist_this_frame / dist_total

	movement_percentage += perc_this_frame

	if movement_percentage >= 1:
		curr_tile = next_tile
		movement_percentage = 0;
	
	on_changed.emit(self)
	if _item != null:
		_item.on_changed.emit(_item)


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


func _on_job_started(_j: Job) -> void:
	for c in curr_tile._map.characters:
		if c.curr_tile == closest_job_tile:
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
	
	if _item != null:
		save_dict["item"] = _item.save()

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
		character._job.job_started.connect(character._on_job_started)
	
	if data.has("item"):
		var item := Item.load(map, data["item"])
		character._item = item
		item.character = character

	return character
