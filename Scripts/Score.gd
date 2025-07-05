extends Node
class_name ScoreManager

var log = Logger.new("Score")

@export var score_label: Label

var score = 0
var level = 1
var flags = {}

func _ready():
	# Statistics
	Stat.Sc = self
	
	reset()

func reset():
	score = 0
	level = 1
	flags.clear()

func add_score(score: int):
	self.score += score
	score_label.text = "Score: %s" % self.score
