class_name Stockpile extends Zone
var filter : Dictionary = {}

var items: Array[Item] = []

var haul_jobs: Array[HaulJob] = []


func _init(tiles: Array[Tile]):
	super(tiles, ZoneType.STOCKPILE)
	var tiles_to_delete = []
	for t in _tiles:
		if (t._fixture != null) or (t._job != null and t._job is ConstructionJob):
			tiles_to_delete.append(t)
			continue
			
		for z in GameManager.instance.map_controller.map.zones:
			if z._tiles.has(t):
				tiles_to_delete.append(t)
	for t in tiles_to_delete:
		_tiles.erase(t)
	
	var map = GameManager.instance.map_controller.map
	map.item_manager.item_placed.connect(add_item)
	for key in map._item_prototypes:
		filter[key] = true
		update_haul_jobs(key)


func remove_tile(t: Tile):
	_tiles.erase(t)
	on_changed.emit(self)


func update_haul_jobs(item_type: String):
	if filter[item_type] == true:
		if _tiles.any(func(t):
			if t._job != null:
				return false 
			if t._item != null and t._item.stack_size == t._item.max_stack_size:
				return false
			return true
			):
			var available_tiles = _tiles.filter(func(t):
				if t._job != null:
					return false 
				if t._item != null and t._item.stack_size == t._item.max_stack_size:
					return false
				return true)

			while available_tiles.size() > 0:
				var tile = available_tiles.pick_random()
				var job = HaulJob.new(item_type, tile._map._item_prototypes[item_type].max_stack_size if tile._item == null else tile._item.max_stack_size - tile._item.stack_size, [tile])
				job.job_complete.connect(func(j):
					haul_jobs.erase(j))
				haul_jobs.append(job)
				_tiles[0]._map.job_queue.enqueue(job)
				available_tiles.erase(tile)
	else:
		for hj in haul_jobs:
			if hj.item_type_to_haul == item_type:
				_tiles[0]._map.job_queue.values.erase(hj)
				haul_jobs.erase(hj)


func update(delta: float):
	super(delta)


func set_filter(item_type: String, value: bool):
	filter[item_type] = value
	update_haul_jobs(item_type)


func add_item(t, i): 
	if _tiles.has(t): 
		items.append(i)


func remove_item(i):
	if not items.has(i):
		return
	
	items.erase(i)
