extends Node
class_name TimerHelper

func delay(seconds, callback):
	var t = get_tree().create_timer(seconds)
	t.timeout.connect(callback)
