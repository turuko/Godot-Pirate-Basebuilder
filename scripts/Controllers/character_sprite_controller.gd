class_name CharacterSpriteController extends Node

var character_node_map = {}
var character_sprites = {}

var map: IslandMap 

func _ready():
    _load_sprites()

    map = GameManager.map_controller.map
    map.on_character_created.connect(_on_character_created)

    map.create_character(map.get_tile_at(map._width / 2, map._height / 2))

func _load_sprites() -> void:
    var path = "res://assets/sprites/characters"
    var dir = DirAccess.open(path)

    dir.list_dir_begin()
    while true:
        var file_name = dir.get_next()
        if file_name == "":
            break
        elif not dir.current_is_dir() and not file_name.begins_with(".") and not file_name.ends_with(".import"):
            character_sprites[file_name.split(".")[0]] = load(path + "/" + file_name)
    dir.list_dir_end()

    print("char sprites: " + str(character_sprites.size()) + ", " + str(character_sprites))


func _on_character_created(c: Character) -> void:
    
    var char_node = Sprite2D.new()

    character_node_map[c] = char_node

    char_node.name = c.name
    char_node.position = Vector2(c.x, c.y) * GameManager.UNIT_SIZE
    add_child(char_node)

    char_node.texture = character_sprites["character"]
    char_node.centered = false

    c.on_changed.connect(_on_character_changed)


func _on_character_changed(c: Character) -> void:
    if not character_node_map.has(c):
        printerr("OnCharacterChanged - trying to change visuals for character not in map")
        return

    var char_node = character_node_map[c]
    char_node.position = Vector2(c.x, c.y) * GameManager.UNIT_SIZE