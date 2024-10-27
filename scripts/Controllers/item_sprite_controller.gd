class_name ItemSpriteController extends Node

var item_sprite_scene = preload("res://scenes/prefabs/item_sprite.tscn")

var item_node_map = {}
var item_sprites = {}

var map: IslandMap 

func initialize():
	_load_sprites()

	map = GameManager.instance.map_controller.map

	for key in map.item_manager.all_items:
		for i in map.item_manager.all_items[key]:
			_on_item_created(i)
	
	for c in map.characters:
		if c._item != null:
			_on_item_created(c._item)

	map.on_item_created.connect(_on_item_created)
	map.on_item_destroyed.connect(_on_item_destroyed)

func _load_sprites() -> void:
	var path = "res://assets/sprites/items"
	var dir = DirAccess.open(path)

	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		elif not dir.current_is_dir() and not file_name.begins_with(".") and not file_name.ends_with(".import"):
			item_sprites[file_name.split(".")[0]] = load(path + "/" + file_name)
	dir.list_dir_end()

	print("char sprites: " + str(item_sprites.size()) + ", " + str(item_sprites))


func _on_item_created(i: Item) -> void:
	
	var item_node = item_sprite_scene.instantiate()

	item_node_map[i] = item_node

	item_node.name = i._object_type

	if i.tile != null:
		item_node.position = Vector2(i.tile._position.x, i.tile._position.y) * GameManager.UNIT_SIZE
	elif i.character != null:
		item_node.position = Vector2(i.character.x, i.character.y) * GameManager.UNIT_SIZE
	
	add_child(item_node)

	item_node.get_node("Texture").texture = item_sprites[i._object_type]
	(item_node.get_node("Amount") as Label).text = str(i.stack_size)
	#item_node.get_node("Texture").centered = false
	i.on_changed.connect(_on_item_changed)


func _on_item_destroyed(i: Item):
	print("Calling destroy on an item")
	if not item_node_map.has(i):
		printerr("OnItemDestroyed - trying to delete visuals for item not in map")
		return

	var item_node = item_node_map[i]
	item_node_map.erase(i)
	item_node_map.keys().erase(i)
	item_node.queue_free()

func _on_item_changed(i: Item) -> void:
	if not item_node_map.has(i):
		printerr("OnCharacterChanged - trying to change visuals for character not in map")
		return

	var item_node = item_node_map[i]
	
	(item_node.get_node("Amount") as Label).text = str(i.stack_size)

	if i.tile != null:
		item_node.position = i.tile._position * GameManager.UNIT_SIZE
		item_node.scale = Vector2(1,1)
		item_node.z_index = 0
	elif i.character != null:
		item_node.scale = Vector2(0.5, 0.5)
		item_node.position = Vector2(i.character.x, i.character.y) * GameManager.UNIT_SIZE + Vector2(GameManager.UNIT_SIZE, GameManager.UNIT_SIZE) / 2
		item_node.z_index = 1
