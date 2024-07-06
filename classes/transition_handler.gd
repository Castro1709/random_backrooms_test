extends Node3D

## gets hidden when player is zone B
@export
var node_a : Node3D

## gets hidden when player is zone A
@export
var node_b : Node3D

var disabled : bool = true

func _on_transition_area_a_body_entered(body: Node3D) -> void:
	if disabled: return
	if body is Player:
		node_a.visible = true
		node_b.visible = false


func _on_transition_area_b_body_entered(body: Node3D) -> void:
	if disabled: return
	if body is Player:
		node_b.visible = true
		node_a.visible = false
