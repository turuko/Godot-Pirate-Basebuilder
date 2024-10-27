class_name BuildModeController extends Node

enum BuildMode {
	ZONE,
	FIXTURE,
	NONE,
}

var _build_mode: BuildMode = BuildMode.NONE
var _build_mode_type: String
var lua: LuaAPI
# Called when the node enters the scene tree for the first time.
func _ready():
	lua = LuaAPI.new()
	lua.bind_libraries(["base"])
	if lua.do_string(FileAccess.get_file_as_string("res://scripts/Data/Job/job_actions.lua")) != null:
		printerr("Error loading lua")
	EventBus.fixture_button_pressed.connect(set_build_mode_fixture)
	EventBus.zone_button_pressed.connect(set_build_mode_zone)

func set_build_mode_fixture(args: Array): #string
	
	if args[0] == null:
		_build_mode = BuildMode.NONE
		return
	
	_build_mode = BuildMode.FIXTURE
	_build_mode_type = args[0]


func set_build_mode_zone(args: Array):
	if args[0] == null:
		_build_mode = BuildMode.NONE
		return
	
	_build_mode = BuildMode.ZONE
	_build_mode_type = args[0]


func build(t: Array[Tile]) -> void:
	var map = GameManager.instance.map_controller.map
	match _build_mode:
		BuildMode.FIXTURE:
			var fixture_type = _build_mode_type
			if map.is_fixture_placement_valid(fixture_type, t[0]) and t[0]._job == null:
				#var lua_build = lua.pull_variant("Build")
				var requirements = map.get_fixture_build_requirements(fixture_type)
				var tiles: Array[Tile] = []

				for x_off in range(t[0]._position.x, t[0]._position.x + map._fixture_prototypes[fixture_type]._width):
					for y_off in range(t[0]._position.y, t[0]._position.y + map._fixture_prototypes[fixture_type]._height):
						tiles.append(map.get_tile_at(x_off, y_off))

				var j = ConstructionJob.new(tiles, fixture_type, JobActions.build, requirements[1], requirements[0])

				j.job_cancel.connect(JobActions.build_cancel.bind([]))
				j.job_started.connect(JobActions.construction_start.bind([]))
			
				map.job_queue.enqueue(j)
				print("job queue size: " + str(map.job_queue.size()))
		BuildMode.ZONE:
			var zone_type := Zone.str_to_type(_build_mode_type)
			match zone_type:
				Zone.ZoneType.STOCKPILE:
					print("Creating stockpile")
					map.add_zone(Stockpile.new(t))

