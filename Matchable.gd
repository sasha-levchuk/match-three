class_name Matchable extends Sprite2D
@onready var block := owner as Block
enum Type {
	GREEN,
	BLUE,
	ORANGE,
	#PURPLE,
}
var type: Type


func _ready():
	frame = 1 + type as int
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


func v2i_to_global(v:Vector2i, direction:Vector2i) -> Vector2i:
	return Vector2i(-direction.y, direction.x)*v.x + direction*v.y


func find_matches(direction:=Vector2i.DOWN) -> Result:
	var right :=   block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.LEFT, direction), type)
	var forward := block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.DOWN, direction), type)
	var left :=    block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.RIGHT, direction), type)
	var orthogonal := left + right
	if forward.size()>=4 or orthogonal.size()>=4:
		return Result.new(true, forward+orthogonal, true, Powerup.Type.DISCOBALL)
	if forward.size()>=2 and orthogonal.size()>=2:
		return Result.new(true, forward+orthogonal, true, Powerup.Type.TNT)
	if orthogonal.size()>=3:
		return Result.new(true, orthogonal, true, Powerup.Type.ROCKETH if direction.x else Powerup.Type.ROCKETV)
	if forward.size()>=1 and left.size()>=1:
		var diag_left := block.raycaster.get_block_at_point(v2i_to_global(Vector2i(1,1), direction))
		if diag_left and diag_left.matchable and diag_left.matchable.type==type:
			return Result.new(true, orthogonal+forward+[diag_left], true)
	if forward.size()>=1 and right.size()>=1:
		var diag_right := block.raycaster.get_block_at_point(v2i_to_global(Vector2i(-1,1), direction))
		if diag_right and diag_right.matchable and diag_right.matchable.type==type:
			return Result.new(true, orthogonal+forward+[diag_right], true)
	if orthogonal.size() >= 2:
		return Result.new(true, orthogonal)
	if forward.size() >= 2:
		return Result.new(true, forward)
	return Result.new(false)
