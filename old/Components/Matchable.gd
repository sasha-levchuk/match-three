class_name Matchable extends Sprite2D
@onready var piece := owner as Piece
enum Type {
	SKULL,
	FIRE,
	ICE,
	MAGIC,
}
var type: Type


func _ready():
	frame = 1 + type as int
	piece.name = Type.keys()[type].left(1)
	piece.add_to_group("matchables")


#class Result:
	#var is_success: bool
	#var is_reward: bool
	#var matches: Array
	#var reward: Powerup.Type
	#func _init(_is_success:bool, _matches:Array=[], _is_reward:=false, _reward:=Powerup.Type.FAN):
		#is_success = _is_success
		#matches = _matches
		#is_reward = _is_reward
		#reward = _reward
#
#
#func rotated(main_vec:Vector2i, rotate_to: Vector2i) -> Vector2i:
	#return Vector2i(-main_vec.y, main_vec.x)*rotate_to.x + main_vec*rotate_to.y
#
#
#func find_matches(direction:=Vector2i.DOWN) -> Result:
	#var forward := Game.gather_blocks_toward(block.posi, rotated(direction, Vector2i.DOWN), type)
	#var left := Game.gather_blocks_toward(block.posi, rotated(direction, Vector2i.LEFT), type)
	#var right := Game.gather_blocks_toward(block.posi, rotated(direction, Vector2i.RIGHT), type)
	#var orthogonal := left + right
	#if forward.size()>=4 or orthogonal.size()>=4:
		#return Result.new(true, forward+orthogonal, true, Powerup.Type.DISCOBALL)
	#if forward.size()>=2 and orthogonal.size()>=2:
		#return Result.new(true, forward+orthogonal, true, Powerup.Type.TNT)
	#if orthogonal.size()>=3:
		#return Result.new(true, orthogonal, true, Powerup.Type.ROCKETH if direction.x else Powerup.Type.ROCKETV)
	#if forward.size()>=1 and left.size()>=1:
		#var diag_left := Game.get_block(block.posi+rotated(direction, Vector2i(-1,1)))
		#if diag_left and diag_left.matchable and diag_left.matchable.type==type:
			#return Result.new(true, orthogonal+forward+[diag_left], true)
	#if forward.size()>=1 and right.size()>=1:
		#var diag_right := Game.get_block(block.posi+rotated(direction, Vector2i(1,1)))
		#if diag_right and diag_right.matchable and diag_right.matchable.type==type:
			#return Result.new(true, orthogonal+forward+[diag_right], true)
	#if orthogonal.size() >= 2:
		#return Result.new(true, orthogonal)
	#if forward.size() >= 2:
		#return Result.new(true, forward)
	#return Result.new(false)
