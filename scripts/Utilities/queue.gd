class_name Queue extends RefCounted

var count: int
var queue: Array = [] #TODO: implement a data structure that is able to accomodate different types of jobs, priorities, etc.


func enqueue(data) -> void:
	queue.push_back(data)
	count = queue.size()


func dequeue():
	if queue.size() > 0:
		count -= 1
		return queue.pop_front()
	else:
		return null


func peek_at(idx: int):
	if idx < 0 or idx >= queue.size():
		return null
	return queue[idx]


func reverse() -> Queue:
	var reverse_queue := Queue.new()
	while queue.size() > 0:
		reverse_queue.enqueue(queue.pop_back())
	return reverse_queue


func is_empty() -> bool:
	return queue.size() == 0


func size() -> int:
	return queue.size()
