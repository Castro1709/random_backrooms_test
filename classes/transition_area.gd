extends Area3D

class_name TransitionArea

@export
var avoid_visible : bool = true
@export
var avoided_visible_obj : VisibleOnScreenNotifier3D = null
var player_inside : Player = null

func _ready() -> void:
	body_entered.connect(on_body_entered)
	if avoided_visible_obj != null:
		avoided_visible_obj.screen_exited.connect(obj_not_visible)

func on_body_entered(body:Node3D) -> void:
	if body is Player:
		if avoid_visible and not avoided_visible_obj.is_on_screen():
			do_transition()
		elif not avoid_visible:
			do_transition()
		player_inside = body

func obj_not_visible() -> void:
	if player_inside != null:
		do_transition()

func do_transition() -> void:
	get_tree().change_scene_to_packed(load("res://levels/level_1.tscn"))
