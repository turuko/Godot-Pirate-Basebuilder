class_name Path_AStar2 extends RefCounted
var a_star: AStarGrid2D
var nodes = {}

func _init(m: IslandMap):
	a_star = AStarGrid2D.new()
	a_star.region = Rect2i(0,0, m._width, m._height)
	a_star.default_compute_heuristic = AStarGrid2D.HEURISTIC_CHEBYSHEV
	a_star.default_estimate_heuristic = AStarGrid2D.HEURISTIC_CHEBYSHEV
	a_star.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a_star.update()

	
	for x in range(m._width):
		for y in range(m._height):
			var id = Vector2i(x,y)
			var tile := m.get_tile_at(x,y)

			nodes[tile] = id

			if tile.movement_cost == 0:
				a_star.set_point_solid(nodes[tile])
			else:
				a_star.set_point_weight_scale(id, tile.movement_cost)


func is_clipping_corner(curr: Tile, neigh: Tile) -> bool:
	var dx: int = curr._position.x - neigh._position.x
	var dy: int = curr._position.y - neigh._position.y

	if abs(curr._position.x - neigh._position.x) + abs(curr._position.y - neigh._position.y) == 2:

		if curr._map.get_tile_at(curr._position.x - dx, curr._position.y) != null and curr._map.get_tile_at(curr._position.x - dx, curr._position.y).movement_cost == 0:
			return true

		if curr._map.get_tile_at(curr._position.x, curr._position.y - dy) != null and curr._map.get_tile_at(curr._position.x, curr._position.y - dy).movement_cost == 0:
			return true

	return false


func get_tile_active(t: Tile) -> bool:
	return not a_star.is_point_solid(nodes[t])


func disable_tile(t: Tile):
	a_star.set_point_solid(nodes[t])


func enable_tile(t: Tile):
	a_star.set_point_solid(nodes[t], false)


func set_tile_weight(t: Tile):
	a_star.set_point_weight_scale(nodes[t], t.movement_cost)

func get_path(start_tile: Tile, end_tile: Tile) -> Queue:
	var path: Queue = Queue.new()
	
	print("start tile disabled: ", a_star.is_point_solid(nodes[start_tile]), ", end tile disabled: ", a_star.is_point_solid(nodes[end_tile]))
	
	var ids := Array(a_star.get_id_path(nodes[start_tile], nodes[end_tile]))

	ids.map(func(id): path.enqueue(nodes.find_key(id)))

	return path
