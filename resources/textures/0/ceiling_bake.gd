@tool
extends Node3D

@export
var baked_lights : bool = true : 
	set(v):
		baked_lights = v
		for c : Node3D in get_children():
			if c is OmniLight3D:
				c.light_bake_mode = Light3D.BAKE_STATIC if v else Light3D.BAKE_DYNAMIC

func _ready() -> void:
	if baked_lights:
		for c : Node3D in get_children():
			if c is OmniLight3D:
				if Engine.is_editor_hint():
					c.visible = true
				else:
					c.visible = false
