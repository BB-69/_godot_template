extends Node
class_name ResultManager

var log = Logger.new("Result")

@export_group("Result Page")
@export var final_score_label: Label

func _ready():
	Stat.Rs = self
	
	show_result()

func _unhandled_input(event):
	if Stat.loading: return
	
	if event.is_action_pressed("ui_accept"):
		await Loader.change_scene("Game")
	elif Input.is_action_just_pressed("ui_cancel"):
		await Loader.change_scene("Main")

func show_result():
	var d: Dictionary = Data.load_data()
	
	final_score_label.text = "Final Score: %s" % d["score"]
