extends Node
@export var rules: Array[Rule]


func _ready():
	for rule: Rule in rules:
		rule.setup()


func run(piece: Piece):
	var match_result := MatchResult.new()
	match_result.piece = piece
	for rule: Rule in rules:
		if rule.execute(piece):
			#rule.matches.filter(func(p):p.delete())
			match_result.successful = true
			match_result.matches = rule.matches
			match_result.reward = rule.reward
			break
	Event.match_processed.emit(match_result)
