class_name Explosive extends Tile

enum Type {
	DISCO,
	TNT,
	ROCKETH,
	ROCKETV,
	WINGS,
	NONE,
}

@export var type: Type

signal spawned
signal exploded


func _ready() -> void:
	super._ready()
	set_process(false)
	anim_player.play('spawn')
	await anim_player.animation_finished
	is_idle = true
	spawned.emit()


func explode():
	anim_player.play('explode')
	await anim_player.animation_finished
	exploded.emit()
	delete()




