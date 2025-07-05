extends Node
class_name Logger

var prefix:String = "Log"
var can_output:bool = true

func _init(prefix, can_output = true):
	self.prefix = prefix
	self.can_output = can_output

func p(msg):
	print("[%s]: %s" % [prefix, msg])

func err(msg):
	push_error("[%s //ERR]: %s" % [prefix, msg])
