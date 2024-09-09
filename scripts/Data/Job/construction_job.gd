class_name ConstructionJob extends Job

var _fixture_type: String
var _initial_job_time: float

func _init(t: Tile, fixture_type: String, jobcb: Callable, jt: float = 1 ):
	super(t, JobType.CONSTRUCTION, jobcb, jt)
	_fixture_type = fixture_type
	_initial_job_time = jt
	job_complete.connect(jobcb.bind([fixture_type]))


func work_job(work_time: float) -> bool:
	var did_work = super(work_time)
	if did_work:
		if _job_time >= 0.0:
			if _tile._fixture != null:
				_tile._fixture.update_health( (work_time / _initial_job_time) * _tile._fixture._max_health)
	return did_work
	

func save():
	var base_save = super()
	base_save["fixture_type"] = _fixture_type
	return base_save


static func load(map: IslandMap, data: Dictionary) -> ConstructionJob:
	var job := super(map, data)

	var c_job := job as ConstructionJob
	c_job._fixture_type = data["fixture_type"]
	if c_job.job_complete.is_connected(Callable(JobActions, data["job_complete_name"])):
		c_job.job_complete.disconnect(Callable(JobActions, data["job_complete_name"]))
	c_job.job_complete.connect(Callable(JobActions, data["job_complete_name"]).bind([c_job._fixture_type]))
	print("c_job: ", c_job)
	return c_job
