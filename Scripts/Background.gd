extends Node2D
class_name BGManager

var log = Logger.new("BG")

@onready var tex_rect = $CanvasLayer/TextureRect

@export var bg_texture: Texture

var bgs:Dictionary = {}

func _ready():
	if bg_texture:
		tex_rect.texture = bg_texture
	else:
		set_bg_color(Color(0.5,0.5,0.5))
	
	var bgloaded:bool = _loadbg()
	if !bgloaded: return

func _loadbg() -> bool:
	var folder_path = "res://Assets/BG/"
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
					var path = "res://bgs/" + file_name
					var texture = load(path)
					var key_name = file_name.get_basename()
					bgs[key_name] = texture
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		log.p("Couldn't open the folder!")
		return false
	
	if !bgs.is_empty(): log.p("Loaded %s bgs!" % bgs.size())
	return true

func set_bg(name:String):
	tex_rect.texture = bgs[name]

func set_bg_color(color:Color):
	var new_texture:GradientTexture1D = GradientTexture1D.new()
	var new_gradient:Gradient = Gradient.new()
	new_gradient.colors = [color]
	new_texture.gradient = new_gradient
	tex_rect.texture = new_texture
