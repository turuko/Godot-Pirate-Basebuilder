extends Node

#UI related events
signal sand_button_pressed(args: Array) # no args
signal remove_button_pressed(args: Array) # no args
signal wall_button_pressed(args: Array) #string

var ui_signals: Dictionary = {
    "sand_button_pressed"  : sand_button_pressed, 
    "remove_button_pressed": remove_button_pressed,
    "wall_button_pressed"  : wall_button_pressed,
    }

func emit_ui_button(s: String, args: Array) -> void:
    ui_signals[s].emit(args)
