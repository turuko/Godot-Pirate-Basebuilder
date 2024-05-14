class_name Path_AStar2 extends RefCounted

#var path: Queue #Queue<Tile>
var a_star: AStar2D
var nodes = {}

func _init(m: IslandMap):
	a_star = AStar2D.new()
	
	for x in range(m._width):
		for y in range(m._height):
			var id = y + x * m._width
			var tile := m.get_tile_at(x,y)
			a_star.add_point(id, Vector2(x,y))

			nodes[tile] = id

			if tile.movement_cost == 0:
				a_star.set_point_disabled(nodes[tile])
			else:
				a_star.set_point_weight_scale(id, (1.0/tile.movement_cost))

			

	for t in nodes:

		var neighbours = t.get_neighbours(true)

		for n in neighbours:
			if n != null:

				if is_clipping_corner(t,n):
					continue

				a_star.connect_points(nodes[t], nodes[n])


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
	return not a_star.is_point_disabled(nodes[t])


func disable_tile(t: Tile):
	a_star.set_point_disabled(nodes[t])

	for n in t.get_neighbours(true):
		if n == null:
			continue
		for n1 in n.get_neighbours(true):
			if n1 == null:
				continue
			if is_clipping_corner(n, n1):
				a_star.disconnect_points(nodes[n], nodes[n1])


func enable_tile(t: Tile):
	a_star.set_point_disabled(nodes[t], false)


func get_path(start_tile: Tile, end_tile: Tile) -> Queue:
	var path: Queue = Queue.new()
	
	var ids := Array(a_star.get_id_path(nodes[start_tile], nodes[end_tile]))

	ids.map(func(id): path.enqueue(nodes.find_key(id)))

	return path
