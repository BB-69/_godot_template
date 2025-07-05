extends Node
class_name DataTemplate

var data: Dictionary = {
	"score": 0,
}

func _init(
	score: int
):
	data["score"] = score
	
