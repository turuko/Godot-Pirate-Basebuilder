class_name JobQueue extends RefCounted

signal job_enqueued(j: Job)

var queue: Queue = Queue.new()#TODO: implement a data structure that is able to accomodate different types of jobs, priorities, etc.


func enqueue(j: Job) -> void:
	queue.enqueue(j)
	job_enqueued.emit(j)


func dequeue() -> Job:
	return queue.dequeue()


func is_empty() -> bool:
	return queue.is_empty()


func size() -> int:
	return queue.size()