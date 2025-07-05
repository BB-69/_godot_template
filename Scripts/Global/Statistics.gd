extends Node

# === Object ===
var id_count: int = 0

# === Game ===
var Camera
var ScreenSize:= Vector2.ZERO
var loading:bool = false

# === Manager ===
var mngs = [Aud, Ptc, Ma, Gm, Sc]
var Aud: AudioManager
var Ptc: ParticleManager
var Ma: MainMenuManager
var Gm: GameManager
var Rs: ResultManager
var Sc: ScoreManager

# === Player ===
var empty:= ""

# === Data ===
var score: int

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_connect_signals()
	_set_data_live()

var signal_connected:= false
func _connect_signals():
	if Gm and Sc: if !Gm.has_connections("add_score"): Gm.connect("add_score", Callable(Sc, "add_score"))

func set_loading(loading:bool): self.loading = loading

func _set_data_live():
	if Sc: score = Sc.score

func is_offscreen(obj) -> bool:
	if !Camera: return false
	if abs(obj.global_position.x - Camera.global_position.x) > ScreenSize.x + 256:
		return true
	if abs(obj.global_position.y - Camera.global_position.y) > ScreenSize.y + 256:
		return true
	return false





# =============== Game State ===============
enum GameState {Idle, Ongoing, Gameover}
const game_scene = preload("res://Scenes/game.tscn")

func _on_gameover():
	reset()
	get_tree().reload_current_scene()

func reset():
	id_count = 0
	
	Camera = null
	ScreenSize = Vector2.ZERO
	
	for mng in mngs: if mng: mng.queue_free()
	
	signal_connected = false
