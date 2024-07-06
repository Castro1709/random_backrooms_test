extends Area3D

class_name InteractiveZone

@export
var hover_message : String = "Grab"

@export
## Can only be used once in a lifetime
var one_use : bool = true
## prevent it from being used again
var used : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.current_player.interacted.connect(on_player_interacted)

func on_player_interacted(interacted_obj:Node3D) -> void:
	if interacted_obj == self and not used:
		_action()
		if one_use:
			used = true

## emitted when the player interacts with the object
func _action() -> void:
	pass
