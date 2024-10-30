#TODO: Replace this with LUA scripting
class_name JobActions


#
# General functions
#


static func job_completed( j: Job, _params: Array):
	for t in j._tiles:
		t._job = null


#
# Construction functions
#

static func build( j: Job, fixture_type: Array ):
	var map = GameManager.instance.map_controller.map
	if j._tiles[0]._fixture == null or j._tiles[0]._fixture._fixture_type != "Construction_Placeholder":
		printerr("No placeholder for construction job")
		return
	for x_off in range(j._tiles[0]._position.x, j._tiles[0]._position.x + map._fixture_prototypes[fixture_type[0]]._width):
		for y_off in range(j._tiles[0]._position.y, j._tiles[0]._position.y + map._fixture_prototypes[fixture_type[0]]._height):
			map.get_tile_at(x_off, y_off).place_fixture(null)
	map.place_fixture(fixture_type[0], j._tiles[0])
	for t in j._tiles:
		t._job = null


static func construction_start(j: Job, _params: Array):
	var map = GameManager.instance.map_controller.map
	for x_off in range(j._tiles[0]._position.x, j._tiles[0]._position.x + map._fixture_prototypes[j._fixture_type]._width):
		for y_off in range(j._tiles[0]._position.y, j._tiles[0]._position.y + map._fixture_prototypes[j._fixture_type]._height):
			map.place_fixture("Construction_Placeholder", map.get_tile_at(x_off, y_off))


static func build_cancel( j: Job, _params: Array): 
	for t in j._tiles:
		t._job = null

#
# Bulldoze functions
#

static func bulldoze(j: Job, _params: Array):
	var fixture = j._tiles[0]._fixture

	if fixture == null:
		printerr("Bulldozing on a tile with no fixture")
		return

	j._tiles[0].place_fixture(null)
	


#
# Haul functions
#
