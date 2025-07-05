extends Node
class_name ParticleController
var ptc: ParticleManager

var log= Logger.new("Particle")

func _ready() -> void:
	if get_parent() is ParticleManager: ptc = get_parent()
	else: log.err("Parent of this node is not 'ParticleManager'!")

func _process(delta: float) -> void:
	pass
