class_name PriorityQueue

class PriorityQueueItem:
    var data
    var priority: float

    func _init(data, priority: float):
        self.data = data
        self.priority = priority

var priority_queue : Array[PriorityQueueItem] = []

func enqueue(data, priority: float):
    var new_item = PriorityQueueItem.new(data, priority)
    var index = 0

    for i in range(priority_queue.size()):
        if priority_queue[i].priority < priority:
            break
        index += 1
    
    priority_queue.insert(index, new_item)


func dequeue():
    if priority_queue.size() > 0:
        return priority_queue.pop_front().data
    else:
        return null


func has(data) -> bool:
    return priority_queue.any(func(item): return item.data == data) 
    

func is_empty() -> bool:
    return priority_queue.size() == 0


func size() -> int:
    return priority_queue.size()