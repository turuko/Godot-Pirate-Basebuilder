class_name BuildModeController extends Node

var _build_mode_tile_type: Tile.TileType = Tile.TileType.SAND
var _build_mode_is_fixture: bool = false
var _build_mode_fixture_type: String

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.sand_button_pressed.connect(set_build_mode_sand)
	EventBus.remove_button_pressed.connect(set_build_mode_water)
	EventBus.wall_button_pressed.connect(set_build_mode_fixture)


func set_build_mode_sand(_args):
	_build_mode_is_fixture = false
	_build_mode_tile_type = Tile.TileType.SAND


func set_build_mode_water(_args):
	_build_mode_is_fixture = false
	_build_mode_tile_type = Tile.TileType.WATER


func set_build_mode_fixture(args: Array): #string
	_build_mode_is_fixture = true
	_build_mode_fixture_type = args[0]

func build(t: Tile) -> void:
	if _build_mode_is_fixture:
		var fixture_type = _build_mode_fixture_type

		if GameManager.map_controller.map.is_fixture_placement_valid(fixture_type, t) and t.fixture_job == null:
			var j = Job.new(t, fixture_type, (func(the_job: Job): 
				GameManager.map_controller.map.place_fixture(fixture_type, the_job._tile)
				the_job._tile.fixture_job = null
				))

			j.job_cancel.connect(func(the_job): the_job._tile.fixture_job = null)
			t.fixture_job = j
		
			GameManager.map_controller.map.job_queue.enqueue(j)
			print("job queue size: " + str(GameManager.map_controller.map.job_queue.size()))
	else:
		t._type = _build_mode_tile_type
