class_name Item extends RefCounted

var _object_type: String
var stack_size: int = 1
var max_stack_size: int

signal on_changed(i: Item)

var tile: Tile:
    set(value):
        if character != null:
            character = null
        tile = value

var character: Character:
    set(value):
        if tile != null:
            tile = null
        character = value


func clone() -> Item:
    var i = Item.new()
    i._object_type = self._object_type
    i.stack_size = self._object_type
    i.max_stack_size = self.max_stack_size

    return i


static func create_prototype(type: String, max_stack: int) -> Item:
    var i = Item.new()
    i._object_type = type
    i.max_stack_size = max_stack
    return i


static func create_instance(proto: Item, amount: int = 1) -> Item:
    if amount > proto.max_stack_size:
        printerr("Cant create stack larger than max stack size")
        return null
    
    var i = proto.clone()
    i.stack_size = amount
    return i


func save():
    var save_dict = {
        "type": _object_type,
        "stack_size": stack_size,
    }

    if tile != null:
        save_dict["tile"] = {"x": tile._position.x, "y": tile._position.y}
    if character != null:
        save_dict["character"] = character.name

    return save_dict


static func load(map: IslandMap, data: Dictionary) -> Item:
    var i = Item.create_instance(map._item_prototypes[data["type"]], data["stack_size"])
    if data.has("tile"):
        map.get_tile_at(data["tile"]["x"], data["tile"]["y"]).place_item(i)

    if data.has("character"):
        i.character = map.get_character(data["character"])
    
    return i