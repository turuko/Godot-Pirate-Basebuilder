#TODO: Replace this with LUA scripting
class_name JobActions

#
# Construction functions
#

static func build( j: Job, fixture_type: Array ):
	if j._tile._fixture == null or j._tile._fixture._fixture_type != "Construction_Placeholder":
		printerr("No placeholder for construction job")
		return
	j._tile.place_fixture(null)
	GameManager.instance.map_controller.map.place_fixture(fixture_type[0], j._tile)
	j._tile.fixture_job = null


static func construction_start(j: Job, _params: Array):
	GameManager.instance.map_controller.map.place_fixture("Construction_Placeholder", j._tile)


static func build_cancel( j: Job, _params: Array): 
	j._tile.fixture_job = null
