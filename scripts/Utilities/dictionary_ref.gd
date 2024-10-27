class_name DictionaryRef extends RefCounted

var data: Dictionary

func _init(source: Dictionary):
    data = source


func __index(_api: LuaAPI, key:Variant):
    return data[key] if data.has(key) else null


func __newindex(_api: LuaAPI, key: Variant, value: Variant):
    data[key] = value
    return RefCounted.new()