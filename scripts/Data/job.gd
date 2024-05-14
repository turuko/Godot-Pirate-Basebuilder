class_name Job extends RefCounted

signal job_complete(j: Job)
signal job_cancel(j: Job)

var _tile: Tile

var _job_time: float

#TODO: I dont like how "fragile" this implementation is to differentiate different jobs.
#      Design a more rubust implementation, that still keeps this class as generic as possible. 
var _job_object_type: String


func _init(t: Tile, jot: String, jobcb: Callable, jt: float = 1 ):
    _tile = t
    _job_time = jt
    _job_object_type = jot
    job_complete.connect(jobcb)


func work_job(work_time: float):
    _job_time -= work_time

    if _job_time <= 0.0:
        job_complete.emit(self)


func cancel_job():
    job_cancel.emit(self)