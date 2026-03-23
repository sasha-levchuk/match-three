class_name Matchable extends Node
@onready var block := owner as Block
enum Type {
	GREEN,
	BLUE,
	ORANGE,
	PURPLE,
}
var type: Type
var type_str: Type:
	get: return Type.keys()[type]


func _ready():
	%MatchableSprite.frame = 1 + type as int
	block.name = Type.keys()[type].left(1)


class Result:
	var is_success: bool
	var is_reward: bool
	var matches: Array
	var reward: Powerup.Type
	func _init(_is_success:bool, _matches:Array=[], _is_reward:=false, _reward:=Powerup.Type.FAN):
		is_success = _is_success
		matches = _matches
		is_reward = true
		reward = _reward


func v2i_to_global(v:Vector2i, direction:Vector2i) -> Vector2i:
	return Vector2i(-direction.y, direction.x)*v.x + direction*v.y


func find_matches(match_block:=block, direction:=Vector2i.DOWN) -> Result:
	var right :=   match_block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.LEFT, direction), type)
	var forward := match_block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.DOWN, direction), type)
	var left :=    match_block.raycaster.gather_neighbors_toward(v2i_to_global(Vector2i.RIGHT, direction), type)
	var orthogonal := left + right
	if forward.size()>=4 or orthogonal.size()>=4:
		return Result.new(true, forward+orthogonal, Powerup.Type.DISCOBALL)
	if forward.size()>=2 and orthogonal.size()>=2:
		return Result.new(true, forward+orthogonal, Powerup.Type.TNT)
	if orthogonal.size()>=3:
		return Result.new(true, orthogonal, Powerup.Type.ROCKETH if direction.x else Powerup.Type.ROCKETV)
	if forward.size()>=1 and left.size()>=1:
		var diag_left := match_block.raycaster.get_neighbor_of_type(v2i_to_global(Vector2i(1,1), direction), type)
		if diag_left:
			return Result.new(true, orthogonal+forward+[diag_left], Powerup.Type.FAN)
	if forward.size()>=1 and right.size()>=1:
		var diag_right := match_block.raycaster.get_neighbor_of_type(v2i_to_global(Vector2i(-1,1), direction), type)
		if diag_right:
			return Result.new(true, orthogonal+forward+[diag_right], Powerup.Type.FAN)
	if orthogonal.size() >= 2:
		return Result.new(true, orthogonal)
	if forward.size() >= 2:
		return Result.new(true, forward)
	return Result.new(false)
