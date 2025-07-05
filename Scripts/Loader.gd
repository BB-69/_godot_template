extends CanvasLayer
class_name SceneLoader

var log = Logger.new("Scene")

var scene:Dictionary = {
	"": "res://Scenes/_empty.tscn",
	"Main": "res://Scenes/main.tscn",
	"Game": "res://Scenes/game.tscn",
	"Result": "res://Scenes/result.tscn",
}

@onready var fade_rect = $FadeRect
@onready var loading_icon = $LoadingIcon

func _ready():
	fade_rect.show()
	fade_rect.modulate.a = 1.0
	loading_icon.show()
	fade_rect.modulate.a = 1.0
	change_scene("Main", 0.5, [false, true])

func fade_in(node: Variant, duration: float = 0.5):
	node.show()
	node.modulate.a = 1.0
	node.create_tween().tween_property(
		node,
		"modulate:a",
		0.0,
		duration).finished.connect(
			func(): node.hide(),
		)

func fade_out(node: Variant, duration: float = 0.5):
	node.show()
	node.modulate.a = 0.0
	node.create_tween().tween_property(
		node,
		"modulate:a",
		1.0,
		duration
	)

var change_scene_index = 0
func change_scene(set_scene:String, duration:float = 0.5, fades:Array = [true, true], has_load_icon:bool = true):
	var scene_path = scene[set_scene]
	Stat.set_loading(true)
	
	fade_out(fade_rect, duration if fades[0] == true else 0)
	await get_tree().create_timer(duration).timeout
	if has_load_icon:
		fade_out(loading_icon, duration/2.0 if fades[0] == true else 0)
		await get_tree().create_timer(duration/2.0).timeout
	await get_tree().change_scene_to_file(scene_path)
	print("\n-------------CHANGE_SCENE_#%s-------------\n" % change_scene_index)
	change_scene_index += 1
	if set_scene == "":
		log.p("Quitting Game!")
		get_tree().quit()
	else:
		log.p("Loaded %s scene!" % set_scene)
	if has_load_icon:
		fade_in(loading_icon, duration/2.0 if fades[1] == true else 0)
		await get_tree().create_timer(duration/2.0).timeout
	fade_in(fade_rect, duration if fades[1] == true else 0)
	
	Stat.set_loading(false)
