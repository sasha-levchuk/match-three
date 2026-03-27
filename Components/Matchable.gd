class_name Matchable extends Sprite2D
@onready var block := owner as Block
enum Type {
	SKULL,
	FIRE,
	ICE,
	MAGIC,
}
const FRAME := [1, 2, 3, 4]
var type: Type


func _ready():
	frame = FRAME[type as int]
	block.name = Type.keys()[type].left(1)


class Result:
	var is_success: bool
	var is_reward: bool
	var matches: Array
	var reward: Powerup.Type
	func _init(_is_success:bool, _matches:Array=[], _is_reward:=false, _reward:=Powerup.Type.FAN):
		is_success = _is_success
		matches = _matches
		is_reward = _is_reward
		reward = _reward


func find_matches(direction:=Vector2i.DOWN) -> Result:
	var where := Utils.v2i_rotated(direction, Vector2i.LEFT)
	var right :=   block.raycaster.gather_neighbors_toward(where, type)
	where = Utils.v2i_rotated(direction, Vector2i.DOWN)
	var forward := block.raycaster.gather_neighbors_toward(where, type)
	where = Utils.v2i_rotated(direction, Vector2i.RIGHT)
	var left :=    block.raycaster.gather_neighbors_toward(where, type)
	var orthogonal := left + right
	if forward.size()>=4 or orthogonal.size()>=4:
		return Result.new(true, forward+orthogonal, true, Powerup.Type.DISCOBALL)
	if forward.size()>=2 and orthogonal.size()>=2:
		return Result.new(true, forward+orthogonal, true, Powerup.Type.TNT)
	if orthogonal.size()>=3:
		return Result.new(true, orthogonal, true, Powerup.Type.ROCKETH if direction.x else Powerup.Type.ROCKETV)
	if forward.size()>=1 and left.size()>=1:
		var diag_left := block.raycaster.get_block_at_point(Utils.v2i_rotated(direction, Vector2i(1,1)))
		if diag_left and diag_left.matchable and diag_left.matchable.type==type:
			return Result.new(true, orthogonal+forward+[diag_left], true)
	if forward.size()>=1 and right.size()>=1:
		var diag_right := block.raycaster.get_block_at_point(Utils.v2i_rotated(direction, Vector2i(-1,1)))
		if diag_right and diag_right.matchable and diag_right.matchable.type==type:
			return Result.new(true, orthogonal+forward+[diag_right], true)
	if orthogonal.size() >= 2:
		return Result.new(true, orthogonal)
	if forward.size() >= 2:
		return Result.new(true, forward)
	return Result.new(false)
