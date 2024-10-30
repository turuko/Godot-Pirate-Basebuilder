class_name Room extends RefCounted

enum RoomType {
	BEDROOM,
	INN,
	HOSPITAL,
	PRISON,
	DOCK,
	BASIC,
}

static func pretty_print_type(t: RoomType) -> String:
	match t:
		RoomType.BEDROOM:
			return "Bedroom"
		RoomType.INN:
			return "Inn"
		RoomType.HOSPITAL:
			return "Hospital"
		RoomType.PRISON:
			return "Prison"
		RoomType.DOCK:
			return "Dock"
		RoomType.BASIC:
			return "Basic"
		_: return ""

static var room_type_requirements = {
	RoomType.DOCK: [(func(r: Room):
		for f in r._fixtures:
			if f._fixture_type == "DockManagementDesk": return true
		return false),
		(func(r: Room):
			for t in r._tiles:
				for z in t._map.zones:
					if z.type == Zone.ZoneType.STOCKPILE:
						if z._tiles.has(t):
							return true
			return false)]
}

var _tiles: Array[Tile] = []
var _fixtures: Array[Fixture] = []

var temperature: float = 0
var splendor: float = 0
var room_name: String
var type: RoomType = RoomType.BASIC


func _init(n: String):
	room_name = n


func assign_tile(t: Tile):
	if _tiles.has(t):
		return

	if t._room != null:
		t._room._tiles.erase(t)

	t._room = self
	_tiles.append(t)


func add_fixture(f: Fixture):
	_fixtures.append(f)
	#Check if adding the new fixture turns the room into one of a special type
	type = Room.check_type_requirements(self)
	

func update_room_type():
	type = Room.check_type_requirements(self)


func unassign_all_tiles():
	for t in _tiles:
		t._room = t._map.get_outside_room()
	
	_tiles = []

static func enclosed_area(source_tile: Tile) -> bool:
	var visited = []
	if source_tile == null or (source_tile._fixture == null or source_tile._fixture._room_blocker == false):
		return false
	return dfs(source_tile, source_tile, null, visited)


static func dfs(start_tile: Tile, current_tile: Tile, previous_tile: Tile, visited: Array) -> bool:
	# Loop through all neighbors of the current tile
	for n in current_tile.get_neighbours(false):
		# Skip if the neighbor is null, doesn't have a fixture, or isn't a room blocker
		if n == null or (n._fixture == null or n._fixture._room_blocker == false):
			continue

		# If we return to the start tile and this isn't the initial call, we've found an enclosed area
		if n == start_tile and current_tile != start_tile:
			if previous_tile == start_tile:
				return false
			return true
		
		# Skip if the neighbor has already been visited
		if visited.has(n):
			continue
		
		# Mark the neighbor as visited
		visited.append(n)

		# Recursively perform DFS on the neighbor
		if dfs(start_tile, n, current_tile, visited):
			return true

	# If no enclosed area was found in any of the neighbors, return false
	return false


static func room_flood_fill(source_fixture: Fixture):

	var map := source_fixture.tile._map

	var old_room = source_fixture.tile._room

	old_room._tiles.erase(source_fixture.tile)
	source_fixture.tile._room = null

	if enclosed_area(source_fixture.tile) == false:
		return
	

	for t in source_fixture.tile.get_neighbours(true):
		_flood_fill(t, old_room)

	var outside = map.get_outside_room()
	if old_room != outside:
		if old_room._tiles.size() > 0:
			printerr("'old_room' still has tiles assigned to it!")
		map.delete_room(old_room)


static func _flood_fill(tile: Tile, old_room: Room):
	if tile == null:
		#Trying to flood fill of the map (likely will never happen as map is bordered by water)
		return

	if tile._room != old_room:
		return

	if tile._fixture != null and tile._fixture._room_blocker:
		return

	if tile._type == Tile.TileType.WATER:
		return

	var new_room = Room.new("Room " + str(tile._map.rooms.size()))
	var tiles_to_check : Queue = Queue.new()
	tiles_to_check.enqueue(tile)

	var tile_counter = 0
	var max_tiles_per_frame = 150

	while tiles_to_check.size() > 0 :
		var t = tiles_to_check.dequeue()

		if t._room == old_room:
			new_room.assign_tile(t)

			var ns = t.get_neighbours(true)

			for t2 in ns:
				if t2 == null or t2._type == Tile.TileType.WATER:
					new_room.unassign_all_tiles()
					return;

				if t2._room == old_room && (t2._fixture == null || t2._fixture._room_blocker == false):
					tiles_to_check.enqueue(t2)
		
		tile_counter += 1
		if tile_counter >= max_tiles_per_frame:
			await GameManager.instance.get_tree().process_frame
			tile_counter = 0
	

	for t in new_room._tiles:
		if t._fixture != null:
			new_room.add_fixture(t._fixture)
	tile._map.add_room(new_room)


static func check_type_requirements(r: Room) -> RoomType:
	for key in room_type_requirements:
		if room_type_requirements[key].all(func(c): return c.call(r) == true):
			return key
	return RoomType.BASIC


func save():
	var save_dict = {
		"room_name": room_name,
		"splendor": splendor,
		"temperature": temperature,
	}

	var tiles_data = []
	for t in _tiles:
		var tile_data = {"x": t._position.x, "y": t._position.y}
		tiles_data.append(tile_data)
	save_dict["tiles"] = tiles_data


	return save_dict


static func load(map: IslandMap, data: Dictionary) -> Room:
	var r = Room.new(data["room_name"])

	r.splendor = data["splendor"]
	r.temperature = data["temperature"]

	for t in data["tiles"]:
		r._tiles.append(map.get_tile_at(t["x"], t["y"]))
	
	return r
