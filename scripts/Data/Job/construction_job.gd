class_name ConstructionJob extends Job

var _fixture_type: String
var _initial_job_time: float
var _required_items: Dictionary
var _items: Dictionary
var _has_required_items: bool:
	get:
		for key in _required_items:
			if not has_enough_of_item(key): return false
		return true


func has_enough_of_item(item_type: String) -> bool:
	if not _items.has(item_type): return false
	return _required_items[item_type] == 0


func _init(t: Array[Tile], fixture_type: String, jobcb: Callable, ri: Dictionary, jt: float = 1 ):
	super(t, JobType.CONSTRUCTION, jt)
	_fixture_type = fixture_type
	_initial_job_time = jt
	_required_items = ri
	_items = {}
	job_complete.connect(jobcb.bind([fixture_type]))


func add_item(item: Item):
	if not _items.has(item._object_type):
		_items[item._object_type] = []
	
	_items[item._object_type].append(item)
	_required_items[item._object_type] -= item.stack_size
	var c = item.character
	item.character = null
	c._item = null
	_tiles[0]._map.on_item_destroyed.emit(item) 


func work_job(work_time: float) -> bool:
	if not _has_required_items:
		return false
	var did_work = super(work_time)
	if did_work:
		if _job_time >= 0.0:
			if _tiles[0]._fixture != null:
				_tiles[0]._fixture.update_health( (work_time / _initial_job_time) * _tiles[0]._fixture._max_health)
	
	return did_work
	

func save():
	var base_save = super()
	base_save["fixture_type"] = _fixture_type
	base_save["required_items"] = _required_items

	var items_data = {}

	for k in _items.keys():
		var values = []
		for i in _items[k] as Array[Item]:
			values.append(i.save())
		items_data[k] = values

	base_save["items"] = items_data

	return base_save


static func load(map: IslandMap, data: Dictionary) -> ConstructionJob:
	var job := super(map, data)

	var c_job := job as ConstructionJob
	c_job._fixture_type = data["fixture_type"]

	var items_data = data["items"]

	for k in items_data.keys():
		var values = []
		for i in items_data[k]:
			values.append(Item.load(map, i))
		c_job._items[k] = values 

	if c_job.job_complete.is_connected(Callable(JobActions, data["job_complete_name"])):
		c_job.job_complete.disconnect(Callable(JobActions, data["job_complete_name"]))
	c_job.job_complete.connect(Callable(JobActions, data["job_complete_name"]).bind([c_job._fixture_type]))

	return c_job
