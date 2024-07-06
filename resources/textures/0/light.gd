extends OmniLight3D

@export
var ignore : bool = false

func _process(delta: float) -> void:
	var distance : float = Player.current_player.global_position.distance_to(self.global_position)
	visible = distance < 60.0 and !ignore

func _ready() -> void:
	#shadow_enabled = randf()<0.5
	pass
