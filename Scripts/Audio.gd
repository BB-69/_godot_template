extends Node2D
class_name AudioManager
@export var audc: AudioController

var log = Logger.new("Audio")

@onready var sound_path = $Continuous
@onready var oneshot_sound_path =$Oneshot

var sounds:= {}
var oneshot_sounds:= {}
var sound_scenes:= {}
var oneshot_sound_scenes:= {}
var audio_pool:= {}
var continuous_audio_pool := {}
var continuous_audio_links := {}

func _ready() -> void:
	# Statistics
	Stat.Aud = self
	
	_init_audios()
	_load_audio_scenes("res://Scenes/Audio/Continuous/", sound_scenes)
	_load_audio_scenes("res://Scenes/Audio/Oneshot/", oneshot_sound_scenes)
	
	if !sound_scenes.is_empty(): log.p("Loaded continuous sounds: %s" % sound_scenes.keys())
	if !oneshot_sound_scenes.is_empty(): log.p("Loaded oneshot sounds: %s" % oneshot_sound_scenes.keys())

func _init_audios():
	if sound_path:
		for node in sound_path.get_children():
			var value_name = node.name
			sounds[node] = value_name
		if !sounds.is_empty(): log.p("Init continuous sounds: %s" % sounds.values())
	else:
		log.err("Could not found sound path: " + sound_path)
	
	if oneshot_sound_path:
		for node in oneshot_sound_path.get_children():
			var value_name = node.name
			oneshot_sounds[node] = value_name
		if !oneshot_sounds.is_empty(): log.p("Init oneshot sounds: %s" % oneshot_sounds.values())
	else:
		log.err("Could not found sound path: " + oneshot_sound_path)

func _load_audio_scenes(folder_path: String, target_dict: Dictionary):
	var dir := DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var key_name = file_name.get_basename()
				var scene_path = folder_path + file_name
				target_dict[key_name] = load(scene_path)
				if continuous_audio_pool.find_key(key_name) != null:
					continuous_audio_pool[key_name] = []
			file_name = dir.get_next()
	else:
		log.err("Could not open folder: " + folder_path)

func get_sound(audio_name: String):
	var sound_node = _get_sound_node(audio_name)
	
	if sound_node: 
		if sound_node is AudioStreamPlayer2D:
			return sound_node
		else: log.err("Can't return '%s' if it's not 'AudioStreamPlayer2D' node." % audio_name)
	else:
		log.err("Audio '%s' not found." % audio_name)
		return null

func play_sound(audio_name: String, playing:= true):
	var sound_node = _get_sound_node(audio_name)
	
	if sound_node:
		if sound_node is AudioStreamPlayer2D:
			if playing: sound_node.play()
			else: sound_node.stop()
		elif sound_node is Node2D:
			_group_play_sound(sound_node, playing)
		else:
			log.err("Audio '%s' are neither 'AudioStreamPlayer2D' or 'Node2D' node." % audio_name)
			return null
	else:
		log.err("Audio '%s' not found." % audio_name)
		return null

func _get_sound_node(audio_name: String):
	var sound_node
	var is_one_shot:= true
	
	# Check current sounds
	for node in sounds:
		if sounds[node] == audio_name:
			is_one_shot = false
			if node is AudioStreamPlayer2D: if !node.playing:
				return node
			elif node.get_class() == "Node2D": if !_group_get_longest_sound(node).playing:
				return node
	
	for node in oneshot_sounds:
		if oneshot_sounds[node] == audio_name:
			is_one_shot = true
			if node is AudioStreamPlayer2D: if !node.playing:
				return node
			elif node.get_class() == "Node2D": if !_group_get_longest_sound(node).playing:
				return node
	
	# Instantiate new
	if is_one_shot:
		return _get_sound_instance(audio_name, oneshot_sounds)
	else:
		return _get_sound_instance(audio_name, sounds)

func _group_get_longest_sound(audio_parent: Node2D) -> AudioStreamPlayer2D:
	var max_duration:= 0.0
	var longest_sound: AudioStreamPlayer2D
	
	for sound in audio_parent.get_children():
		log.p(sound)
		if sound is AudioStreamPlayer2D and sound.stream and sound.stream.get_length() > max_duration:
			longest_sound = sound
			max_duration = sound.stream.get_length()
	
	if longest_sound: return longest_sound
	else:
		log.err("Where da longest sound u no u NEED one.")
		return null

func _group_play_sound(audio_parent: Node2D, playing:= true):
	if audio_parent == null: return
	for audio in audio_parent.get_children():
		if audio is AudioStreamPlayer2D:
			if playing: audio.play()
			else: audio.stop()

func _get_sound_instance(audio_name: String, audio_list: Dictionary):
	var new_node
	if sound_scenes.has(audio_name): new_node = sound_scenes[audio_name].instantiate()
	elif oneshot_sound_scenes.has(audio_name): new_node = oneshot_sound_scenes[audio_name].instantiate()
	else: log.err("Audio '%s' not found." % audio_name)
	add_child(new_node)
	audio_list[new_node] = audio_name
	return new_node

func get_or_link_continuous(audio_name: String, obj) -> AudioStreamPlayer2D:
	var obj_id = obj.base.id
	var current_pos = obj.global_position
	
	# First, check if this object is already linked
	for sound in continuous_audio_links:
		if continuous_audio_links[sound] == ("%s-%s" % [audio_name, obj_id]):
			sound.global_position = current_pos
			return sound
	
	# Then, try to find a free one
	var free_pool = continuous_audio_pool.get(audio_name, [])
	for sound in free_pool:
		continuous_audio_links[sound] = ("%s-%s" % [audio_name, obj_id])
		free_pool.erase(sound)
		sound.global_position = current_pos
		return sound
	
	# None free? Spawn new
	var scene = sound_scenes.get(audio_name)
	if scene:
		var new_instance = scene.instantiate()
		new_instance.global_position = current_pos
		add_child(new_instance)
		continuous_audio_links[new_instance] = ("%s-%s" % [audio_name, obj_id])
		return new_instance
	
	log.err("No scene found for '%s'" % audio_name)
	return null

func release_continuous_sound(audio_name: String, obj):
	var obj_id = obj.base.id
	for sound in continuous_audio_links.keys():
		if continuous_audio_links[sound] == ("%s-%s" % [audio_name, obj_id]):
			if is_instance_valid(sound):
				sound.stop()
				continuous_audio_pool[audio_name].append(sound)
			continuous_audio_links.erase(sound)
