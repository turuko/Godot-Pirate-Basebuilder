class_name Queue extends RefCounted

var count: int
var values: Array = [] #TODO: implement a data structure that is able to accomodate different types of jobs, priorities, etc.


func enqueue(data) -> void:

	values.push_back(data)
	count = values.size()


func dequeue():
	if values.size() > 0:
		count -= 1
		return values.pop_front()
	else:
		return null


func peek_at(idx: int):
	if idx < 0 or idx >= values.size():
		return null
	return values[idx]


func reverse() -> Queue:
	var reverse_queue := Queue.new()
	while values.size() > 0:
		reverse_queue.enqueue(values.pop_back())
	return reverse_queue


func is_empty() -> bool:
	return values.size() == 0


func size() -> int:
	return values.size()


func save():
	var save_dict = {
		"count": count,
	}

	var saved_values = []

	for v in values:
		saved_values.push_back(v.save())
	
	save_dict["values"] = saved_values

	return save_dict