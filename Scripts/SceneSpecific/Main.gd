extends Node2D
class_name MainMenuManager

var log = Logger.new("Main")

func _ready():
	Stat.Ma = self

func _unhandled_input(event):
	if Stat.loading: return
	
	if event.is_action_pressed("ui_accept"):
		await Loader.change_scene("Game")
	elif Input.is_action_just_pressed("ui_cancel"):
		await Loader.change_scene("", 0.5, [true, false], false)
