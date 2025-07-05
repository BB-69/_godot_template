extends TextureRect

func _process(delta: float) -> void:
	rotation += 2*PI*delta
