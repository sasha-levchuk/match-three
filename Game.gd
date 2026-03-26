extends Node
signal score_incremented
signal tnt_exploded
var score := 0


func _ready():
	score_incremented.connect(func():score += 1)
