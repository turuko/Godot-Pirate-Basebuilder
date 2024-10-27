extends Node

#UI related events
signal fixture_button_pressed(args: Array) #string
signal zone_button_pressed(args: Array) #string
signal new_world_button_pressed(args: Array) #no args
signal load_button_pressed(args: Array) #no args
signal save_button_pressed(args: Array) #no args

var ui_signals: Dictionary = {
    "fixture_button_pressed"  : fixture_button_pressed,
    "zone_button_pressed": zone_button_pressed,
    "new_world_button_pressed"  : new_world_button_pressed,
    "load_button_pressed"  : load_button_pressed,
    "save_button_pressed"  : save_button_pressed,
    }

func emit_ui_button(s: String, args: Array) -> void:
    ui_signals[s].emit(args)
