extends Node2D
class_name ParticleManager
@export var ptcc: ParticleController

var log = Logger.new("Particle")

@onready var particle_path = $Continuous
@onready var oneshot_particle_path =$Oneshot

var particles:= {}
var oneshot_particles:= {}
var particle_scenes:= {}
var oneshot_particle_scenes:= {}
var particle_pool:= {}
var continuous_particle_pool:= {}
var continuous_particle_links := {}

func _ready() -> void:
	# Statistics
	Stat.Ptc = self
	
	_init_particles()
	_load_particle_scenes("res://Scenes/Particle/Continuous/", particle_scenes)
	_load_particle_scenes("res://Scenes/Particle/Oneshot/", oneshot_particle_scenes)
	
	if !particle_scenes.is_empty(): log.p("Loaded continuous particles: %s" % particle_scenes.keys())
	if !oneshot_particle_scenes.is_empty(): log.p("Loaded oneshot particles: %s" % oneshot_particle_scenes.keys())

func _init_particles():
	if particle_path:
		for node in particle_path.get_children():
			var value_name = node.name
			particles[node] = value_name
		if !particles.is_empty(): log.p("Init continuous particles: %s" % particles.values())
	else:
		log.err("Could not found particle path: " + particle_path)
	
	if oneshot_particle_path:
		for node in oneshot_particle_path.get_children():
			var value_name = node.name
			oneshot_particles[node] = value_name
		if !oneshot_particles.is_empty(): log.p("Init oneshot particles: %s" % oneshot_particles.values())
	else:
		log.err("Could not found particle path: " + oneshot_particle_path)

func _load_particle_scenes(folder_path: String, target_dict: Dictionary):
	var dir := DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var key_name = file_name.get_basename()
				var scene_path = folder_path + file_name
				target_dict[key_name] = load(scene_path)
				if continuous_particle_pool.find_key(key_name) != null:
					continuous_particle_pool[key_name] = []
			file_name = dir.get_next()
	else:
		log.err("Could not open folder: " + folder_path)


func _process(delta: float) -> void:
	pass
	#_check_offscreen_particles()

func _check_offscreen_particles():
	for particle in particles: if Stat.is_offscreen(particle):
		set_particle_childs(particle, false)
		particle.hide()
	else: particle.show()
	for particle in oneshot_particles: if Stat.is_offscreen(particle):
		set_particle_childs(particle, false)
		particle.hide()
	else: particle.show()
	for particle in continuous_particle_links: if Stat.is_offscreen(particle):
		set_particle_childs(particle, false)
		particle.hide()
	else: particle.show()

func get_particle(particle_name: String):
	var particle_node = _get_particle_node(particle_name)
	
	if particle_node: 
		if particle_node is CPUParticles2D:
			return particle_node
		else: log.err("Can't return '%s' if it's not 'CPUParticles2D' node." % particle_name)
	else:
		log.err("Particle '%s' not found." % particle_name)
		return null

func emit_particle(particle_name: String, emitting:= true):
	var particle_node = _get_particle_node(particle_name)
	
	if particle_node:
		if particle_node is CPUParticles2D:
			if emitting: particle_node.emitting = true
			else: particle_node.emitting = false
		elif particle_node is Node2D:
			_group_emit_particle(particle_node, emitting)
		else:
			log.err("Particle '%s' are neither 'CPUParticles2D' or 'Node2D' node." % particle_name)
			return null
	else:
		log.err("Particle '%s' not found." % particle_name)
		return null

func _get_particle_node(particle_name: String):
	var particle_node
	var is_one_shot:= true
	
	# Check current particles
	for node in particles:
		if particles[node] == particle_name:
			is_one_shot = false
			if node is CPUParticles2D: if !node.emitting:
				return node
			elif node.get_class() == "Node2D": if !_group_get_longest_particle(node).emitting:
				return node
	
	for node in oneshot_particles:
		if oneshot_particles[node] == particle_name:
			is_one_shot = true
			if node is CPUParticles2D: if !node.emitting:
				return node
			elif node.get_class() == "Node2D": if !_group_get_longest_particle(node).emitting:
				return node
	
	# Instantiate new
	if is_one_shot:
		return _get_particle_instance(particle_name, oneshot_particles)
	else:
		return _get_particle_instance(particle_name, particles)

func _group_get_longest_particle(particle_parent: Node2D) -> CPUParticles2D:
	var max_duration:= 0.0
	var longest_particle: CPUParticles2D
	
	for particle in particle_parent.get_children():
		log.p(particle)
		if particle is CPUParticles2D and particle.stream and particle.stream.get_length() > max_duration:
			longest_particle = particle
			max_duration = particle.stream.get_length()
	
	if longest_particle: return longest_particle
	else:
		log.err("Where da longest particle u no u NEED one.")
		return null

func _group_emit_particle(particle_parent: Node2D, emitting:= true):
	if particle_parent == null: return
	for particle in particle_parent.get_children():
		if particle is CPUParticles2D:
			if emitting: particle.emitting = true
			else: particle.emitting = false

func _get_particle_instance(particle_name: String, particle_list: Dictionary):
	var new_node
	if particle_scenes.has(particle_name): new_node = particle_scenes[particle_name].instantiate()
	elif oneshot_particle_scenes.has(particle_name): new_node = oneshot_particle_scenes[particle_name].instantiate()
	else: log.err("Particle '%s' not found." % particle_name)
	add_child(new_node)
	particle_list[new_node] = particle_name
	return new_node

func get_or_link_continuous(particle_name: String, obj) -> CPUParticles2D:
	var obj_id = obj.base.id
	var current_pos = obj.global_position
	
	# First, check if this object is already linked
	for particle in continuous_particle_links:
		if continuous_particle_links[particle] == ("%s-%s" % [particle_name, obj_id]):
			particle.global_position = current_pos
			return particle
	
	# Then, try to find a free one
	var free_pool = continuous_particle_pool.get(particle_name, [])
	for particle in free_pool:
		continuous_particle_links[particle] = ("%s-%s" % [particle_name, obj_id])
		free_pool.erase(particle)
		particle.global_position = current_pos
		return particle
	
	# None free? Spawn new
	var scene = particle_scenes.get(particle_name)
	if scene:
		var new_instance = scene.instantiate()
		new_instance.global_position = current_pos
		add_child(new_instance)
		continuous_particle_links[new_instance] = ("%s-%s" % [particle_name, obj_id])
		return new_instance
	
	log.err("No scene found for '%s'" % particle_name)
	return null

func release_continuous_particle(particle_name: String, obj):
	var obj_id = obj.base.id
	for particle in continuous_particle_links.keys():
		if continuous_particle_links[particle] == ("%s-%s" % [particle_name, obj_id]):
			if is_instance_valid(particle):
				particle.emitting = false
				continuous_particle_pool[particle_name].append(particle)
			continuous_particle_links.erase(particle)

func set_particle_childs(node, emitting: bool, visited := {}):
	if node is CPUParticles2D: node.emitting = emitting
	if node in visited:
		return
	visited[node] = true
	
	for child in get_children():
		if child is CPUParticles2D: child.emitting = emitting
		if child.get_children(): set_particle_childs(child, emitting, visited)
