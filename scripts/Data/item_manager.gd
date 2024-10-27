class_name ItemManager extends RefCounted

signal item_placed(t: Tile, i: Item)

var all_items: Dictionary = {} #String, Array


func _init(prototypes: Array):
	for p in prototypes:
		all_items[p] = []


func place_item(item_instance: Item, tile: Tile) -> bool:
	
	var tile_was_empty := tile._item == null 
	
	if tile.place_item(item_instance) == false:
		return false

	if item_instance.stack_size == 0:
		tile._map.on_item_destroyed.emit(item_instance)
		all_items[item_instance._object_type].erase(item_instance)

	if tile_was_empty:
		all_items[item_instance._object_type].append(item_instance)
		item_placed.emit(tile, item_instance)
	
	if item_instance.stack_size != 0:
		item_instance.on_changed.emit(item_instance)
		
	

	return true


func take_item(tile: Tile, amount: int) -> Array:
	if tile._item == null:
		return [false, null]
	
	if amount >= tile._item.stack_size:
		all_items[tile._item._object_type].erase(tile._item)
		var item = tile._item
		tile._item = null
		return [true, item]
	else:
		tile._item.stack_size -= amount
		tile._item.on_changed.emit(tile._item)
		return [true, amount]
	

func is_item_in_stockpile(i: Item) -> bool:
	for s in GameManager.instance.map_controller.map.zones.filter(func(z): return z.type == Zone.ZoneType.STOCKPILE):
		if s.items.has(i): return true
	return false

	
func take_full_stack(tile: Tile) -> Array:
	var item = tile._item
	return take_item(tile, item.stack_size)


func save():
	var save_dict = {}

	var items = {}

	for k in all_items.keys():
		var item_values = []
		for i in all_items[k] as Array[Item]:
			item_values.append(i.save())
		items[k] = item_values

	save_dict["items"] = items
	return save_dict
