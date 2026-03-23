class_name SwapResult

class MatchResult:
	var is_successful := false
	enum Reward {NONE, FAN, ROCKETV, ROCKETH, TNT, DISCOBALL}
	var reward: Reward

var direction: Vector2i
var blocks: Array[Block]
var is_successful := false
var match_results: Array[MatchResult]
var cells_to_delete: Array[Block]


func _init(_direction: Vector2i, _blocks: Array[Block]):
	direction = _direction
	blocks = _blocks
