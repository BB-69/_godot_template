extends Node
class_name TweenHelper

func fade_in(node, duration=0.3):
	node.modulate.a = 0
	node.show()
	node.create_tween().tween_property(node, "modulate:a", 1.0, duration)

func fade_out(node, duration=0.3):
	node.create_tween().tween_property(node, "modulate:a", 0.0, duration).finished.connect(
		func(): node.hide()
	)
