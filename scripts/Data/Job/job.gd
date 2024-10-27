class_name Job extends RefCounted

signal job_complete(j: Job, params: Array)
signal job_cancel(j: Job, params: Array)
signal job_started(j: Job, params: Array)

enum JobType {
	CONSTRUCTION,
	HAUL,
	MISC,
}

var _tiles: Array[Tile]
var _job_type: JobType
var _job_time: float
var _has_started: bool = false

#TODO: I dont like how "fragile" this implementation is to differentiate different jobs.
#      Design a more rubust implementation, that still keeps this class as generic as possible. 



func _init(t: Array[Tile], jot: JobType, jt: float = 1 ):
	_tiles = t
	_job_time = jt
	_job_type = jot

	for t2 in _tiles:
		t2._job = self

	job_complete.connect(JobActions.job_completed.bind([]))


func work_job(work_time: float) -> bool:

	if not _has_started:
		_has_started = true
		job_started.emit(self)
		return false

	_job_time -= work_time

	if _job_time <= 0.0:
		job_complete.emit(self) 
	return true

func cancel_job():
	job_cancel.emit(self)


func save():
	
	var save_dict = {
		"job_time": _job_time,
		"job_type": _job_type,
		"job_complete_name": job_complete.get_connections()[0]["callable"].get_method(),
		"job_cancel_name": job_cancel.get_connections()[0]["callable"].get_method(),
		"job_started_name": job_started.get_connections()[0]["callable"].get_method()
	}

	var tile_data = []
	for t in _tiles:
		tile_data.append({"x": t._position.x, "y": t._position.y})
	save_dict["tiles"] = tile_data


	return save_dict


static func load(map: IslandMap, data: Dictionary) -> Job:
	var complete_name: StringName = data["job_complete_name"]
	var cancel_name: StringName = data["job_cancel_name"]
	var start_name: StringName = data["job_started_name"]

	var tiles: Array[Tile] = []
	for t_data in data["tiles"]:
		var t = map.get_tile_at(t_data["x"], t_data["y"])
		tiles.append(t)

	var job

	match (data["job_type"] as JobType):
		JobType.CONSTRUCTION:
			job = ConstructionJob.new(tiles, "", Callable(JobActions, complete_name), data["required_items"],data["job_time"])
		JobType.MISC:
			job = Job.new(tiles,data["job_type"],data["job_time"])
	job.job_cancel.connect(Callable(JobActions, cancel_name).bind([]))
	job.job_started.connect(Callable(JobActions, start_name).bind([]))

	for t in tiles:
		t._job = job

	return job
