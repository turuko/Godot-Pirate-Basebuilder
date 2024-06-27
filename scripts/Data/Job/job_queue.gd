class_name JobQueue extends RefCounted

signal job_enqueued(j: Job)

var queue: Queue = Queue.new()#TODO: implement a data structure that is able to accomodate different types of jobs, priorities, etc.

#TODO: Implement different queues for each type of job, as well as a way for characters to choose which queue to look at for getting a new job.
var construction_queue: Queue = Queue.new()


func enqueue(j: Job) -> void:
	queue.enqueue(j)
	job_enqueued.emit(j)


func dequeue() -> Job:
	return queue.dequeue()


func is_empty() -> bool:
	return queue.is_empty()


func size() -> int:
	return queue.size()


func save():
	var save_dict = {
		"queue": queue.save()
	}

	return save_dict