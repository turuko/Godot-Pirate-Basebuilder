class_name Zone extends RefCounted

enum ZoneType {
    STOCKPILE,
    #...
}

static func pretty_print_type(t: ZoneType):
    match t:
        ZoneType.STOCKPILE:
            return "Stockpile"
        _: return ""

static func str_to_type(s: String) -> ZoneType:
    return ZoneType.get(s)

var _tiles: Array[Tile] = []

var type: ZoneType

func _init(tiles: Array[Tile], t: ZoneType):
    _tiles = tiles
    type = t


func update(delta: float):
    pass