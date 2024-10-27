class_name ZoneSpriteController extends Node

var zone_scenes = {}
var zone_node_map = {}


func initialize():
    var map = GameManager.instance.map_controller.map
    _load_sprites()

    for z in map.zones:
        _on_zone_created(z)

    map.on_zone_created.connect(_on_zone_created)


func _load_sprites() -> void:
    var path = "res://scenes/prefabs/zones"
    var dir = DirAccess.open(path)

    dir.list_dir_begin()
    while true:
        var file_name = dir.get_next()
        if file_name == "":
            break
        elif not dir.current_is_dir() and not file_name.begins_with(".") and not  file_name.ends_with(".import"):
            var zone_type = Zone.ZoneType.get(file_name.to_upper().split(".")[0])
            zone_scenes[zone_type] = load(path + "/" + file_name)
    dir.list_dir_end()


func _on_zone_created(z: Zone) -> void:
    
    var zone_node = Node.new()
    zone_node_map[z] = zone_node
    zone_node.name = Zone.pretty_print_type(z.type) + " " + str(zone_node_map.size())

    var color = Color(randf(), randf(), randf())
    print("zone tiles: ", z._tiles)
    for t in z._tiles:
        var sprite = zone_scenes[z.type].instantiate()
        sprite.position = Vector2(t._position.x, t._position.y) * GameManager.UNIT_SIZE
        sprite.modulate = color
        zone_node.add_child(sprite)

    add_child(zone_node)