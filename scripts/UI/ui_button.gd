class_name UIButton extends Button

@export var signal_name: String
@export var args: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(func(): 
		EventBus.emit_ui_button(signal_name, args))
