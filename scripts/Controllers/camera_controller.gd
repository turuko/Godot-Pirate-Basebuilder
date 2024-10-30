class_name CameraController extends Camera2D

@export var move_speed: float

@export var zoom_speed: float
@export var zoom_speed_damp: float = 0.5

var _zoom_dir = 0

var min_zoom = Vector2(2.5,2.5)
var max_zoom = Vector2(0.05, 0.05)

func _input(event):
	if event.is_action_pressed("scroll_up"):
		_zoom_dir = 1

	if event.is_action_pressed("scroll_down"):
		_zoom_dir = -1


func _process(delta):
	_move(delta)
	_zoom(delta)


func _zoom(delta: float) -> void:
	if _zoom_dir != 0:
		zoom += zoom * (Vector2(1,1) * _zoom_dir * zoom_speed) * delta
		zoom = zoom.clamp(max_zoom, min_zoom)

		_zoom_dir *= zoom_speed_damp
		if is_zero_approx(abs(_zoom_dir)):
			_zoom_dir = 0


func _move(delta: float) -> void:
	
	#TODO: figure out smoothed movement...
	#var dir = get_screen_center_position().direction_to(get_target_position())
	#if get_screen_center_position().distance_to(get_target_position()) <= 50:
	#	dir = Vector2.ZERO
	#
	##print("dir: " + str(dir))
	#var smoothed_position = get_screen_center_position() + dir * position_smoothing_speed * delta
	#print("smoothed_position: " + str(smoothed_position) + ", screen pos: " + str(get_screen_center_position()) + ", target pos: " + str(get_target_position()))

	if get_screen_center_position().distance_to(get_target_position()) >= 50:
		position = get_screen_center_position()
		return
	
	if Input.is_action_pressed("W"):
		position.y += -move_speed * delta
	if Input.is_action_pressed("S"):
		position.y += move_speed * delta
	if Input.is_action_pressed("A"):
		position.x += -move_speed * delta
	if Input.is_action_pressed("D"):
		position.x += move_speed * delta

	#position = position.floor()


func drag(diff: Vector2) -> void:
	position += (diff / zoom)
	#position = position.floor()
