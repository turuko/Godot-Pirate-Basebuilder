class_name Job extends RefCounted

signal job_complete(j: Job, params: Array)
signal job_cancel(j: Job, params: Array)
signal job_started(j: Job, params: Array)

enum JobType {
	CONSTRUCTION,
	MISC,
}

var _tile: Tile
var _job_type: JobType
var _job_time: float
var _has_started: bool = false

#TODO: I dont like how "fragile" this implementation is to differentiate different jobs.
#      Design a more rubust implementation, that still keeps this class as generic as possible. 



func _init(t: Tile, jot: JobType, _jobcb: Callable, jt: float = 1 ):
	_tile = t
	_job_time = jt
	_job_type = jot


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
		"tile_x": _tile._position.x,
		"tile_y": _tile._position.y,
		"job_time": _job_time,
		"job_type": _job_type,
		"job_complete_name": job_complete.get_connections()[0]["callable"].get_method(),
		"job_cancel_name": job_cancel.get_connections()[0]["callable"].get_method(),
		"job_started_name": job_started.get_connections()[0]["callable"].get_method()
	}

	return save_dict


static func load(map: IslandMap, data: Dictionary) -> Job:
	var complete_name: StringName = data["job_complete_name"]
	var cancel_name: StringName = data["job_cancel_name"]
	var start_name: StringName = data["job_started_name"]
	var tile = map.get_tile_at(data["tile_x"], data["tile_y"])

	var job

	match (data["job_type"] as JobType):
		JobType.CONSTRUCTION:
			job = ConstructionJob.new(tile, "", Callable(JobCallbacks, complete_name),data["job_time"])
		JobType.MISC:
			job = Job.new(tile,data["job_type"], Callable(JobCallbacks, complete_name),data["job_time"])
	job.job_cancel.connect(Callable(JobCallbacks, cancel_name).bind([]))
	job.job_started.connect(Callable(JobCallbacks, start_name).bind([]))
	tile.fixture_job = job

	return job
