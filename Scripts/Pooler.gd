extends Node
class_name Pooler

var scene_path: String
var initial_size: int
var auto_shrink: bool
var shrink_interval: float
var spawn_loop_interval: float

var parent_node: Node = null
var packed_scene: PackedScene
var pool: Array = []
var active_instances: Array = []

var spawn_timer: Timer
var shrink_timer: Timer

func _init(
	scene_path: String,
	initial_size: int = 5,
	auto_shrink: bool = false,
	shrink_interval: float = 10.0,
	spawn_loop_interval: float = 0.0
):
	self.scene_path = scene_path
	self.initial_size = initial_size
	self.auto_shrink = auto_shrink
	self.shrink_interval = shrink_interval
	self.spawn_loop_interval = spawn_loop_interval

func init(parent: Node):
	parent_node = parent
	packed_scene = load(scene_path)
	
	for i in initial_size:
		var inst = _create_instance()
		pool.append(inst)
	
	if auto_shrink:
		shrink_timer = Timer.new()
		shrink_timer.wait_time = shrink_interval
		shrink_timer.one_shot = false
		shrink_timer.autostart = true
		shrink_timer.timeout.connect(_cleanup_unused)
		parent_node.add_child(shrink_timer)
	
	# Setup spawn loop timer
	if spawn_loop_interval > 0.0:
		spawn_timer = Timer.new()
		spawn_timer.wait_time = spawn_loop_interval
		spawn_timer.one_shot = false
		spawn_timer.autostart = true
		spawn_timer.timeout.connect(_on_spawn_loop)
		parent_node.add_child(spawn_timer)

func _create_instance() -> Node:
	var inst = packed_scene.instantiate()
	inst.visible = false
	parent_node.add_child(inst)
	return inst

func get_instance() -> Node:
	var inst: Node = null
	
	# If pool has inactive
	if pool.size() > 0:
		inst = pool.pop_back()
	else:
		inst = _create_instance()
	
	active_instances.append(inst)
	inst.visible = true
	return inst

func release_instance(inst: Node):
	if inst in active_instances:
		active_instances.erase(inst)
	inst.visible = false
	pool.append(inst)

func _cleanup_unused():
	while pool.size() > initial_size:
		var inst = pool.pop_back()
		if is_instance_valid(inst):
			inst.queue_free()

func _on_spawn_loop():
	var inst = get_instance()
