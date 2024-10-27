class_name HaulJob extends Job

var item_type_to_haul


func _init(type: String, amount: int,  tile: Array[Tile]):
    super(tile, JobType.HAUL, amount)
    _has_started = true
    item_type_to_haul = type