class_name SimplePool

const DEFAULT_POOL_SIZE: int = 3

static var pools: Dictionary

class PoolMember extends Node:
    var pool: Pool

class Pool:
    
    var next_id: int = -1

    var inactive: Array[Node2D] = []

    var prefab: PackedScene

    func _init(p: PackedScene, initial_qty: int):
        prefab = p

        inactive.resize(initial_qty)

    
    func spawn(pos: Vector2, rot: float) -> Node2D:
        var n: Node2D

        if inactive.size() == 0:
            n = prefab.instantiate() as Node2D
            n.position = pos
            n.rotation = rot
            next_id += 1
            n.name = prefab.resource_name + " (" + str(next_id) + ")"

            var pool_member = PoolMember.new()
            pool_member.pool = self
            n.add_child(pool_member)
        else:
            n = inactive.pop_back()

            if n == null:

                return spawn(pos, rot)
        
        n.position = pos
        n.rotation = rot
        n.visible = true
        return n


    func despawn(n: Node2D) -> void:
        n.visible = false

        inactive.push_back(n)


static func init(p: PackedScene, qty: int = DEFAULT_POOL_SIZE):
    if pools == null:
        pools = {}
    if p != null and not pools.has(p):
        pools[p] = Pool.new(p, qty)


static func spawn( p: PackedScene, pos: Vector2, rot: float) -> Node2D:
    init(p)

    
    return pools[p].spawn(pos, rot)


static func despawn(n: Node2D) -> void:
    var pm: PoolMember

    for i in range(n.get_child_count()):
        if n.get_child(i) is PoolMember:
            pm = n.get_child(i)
            break

    if pm == null:
        print("object wasn't spawned from pool. destroying")
        n.queue_free()
    else:
        pm.pool.despawn(n)