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
    
    var zone_node = Node2D.new()
    zone_node_map[z] = zone_node
    zone_node.name = Zone.pretty_print_type(z.type) + " " + str(zone_node_map.size())

    var color = Color(randf(), randf_range(0, 0.4), randf())

    for t in z._tiles:
        var sprite = zone_scenes[z.type].instantiate()
        sprite.position = Vector2(t._position.x, t._position.y) * GameManager.UNIT_SIZE
        zone_node.add_child(sprite)
    zone_node.modulate = color

    z.on_changed.connect(on_zone_changed)

    add_child(zone_node)


func on_zone_changed(z: Zone):
    var zone_node: Node2D = zone_node_map[z]
    
    var tiles_left = z._tiles.duplicate()
    for c in zone_node.get_children():
        if not z._tiles.any(func(t): return c.position == Vector2(t._position.x, t._position.y) * GameManager.UNIT_SIZE):
            c.queue_free()
        else:
            var t = tiles_left.filter(func(e): return c.position == Vector2(e._position.x, e._position.y) * GameManager.UNIT_SIZE)[0]
            tiles_left.erase(t)
    if tiles_left.size() > 0:
        for t in tiles_left:
            var sprite = zone_scenes[z.type].instantiate()
            sprite.position = Vector2(t._position.x, t._position.y) * GameManager.UNIT_SIZE
            zone_node.add_child(sprite)
    
        



func highlight_zone(z: Zone):
    var zone_node = zone_node_map[z]
    zone_node.modulate += Color(0.15, 0.15, 0.15)
    

func unhighlight_zone(z: Zone):
    var zone_node = zone_node_map[z]
    zone_node.modulate -= Color(0.15, 0.15, 0.15)