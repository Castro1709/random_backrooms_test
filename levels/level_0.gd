extends Node3D

@export
var sections : Array[PackedScene] = []

var last_chuck := Vector2i(0,0)
var first_load : bool = true
var loaded_sections : Dictionary = {}
var generated_chunks : int = 0
const CHUNK_SIZE := 54 # 27
const MAX_CHUNCKS := 3
const MIDDLE_CHUNCK := 2
const CHUCK_RADIUS := MAX_CHUNCKS - MIDDLE_CHUNCK

func _process(_delta: float) -> void:
	if first_load:
		first_load = false
		for x_i in MAX_CHUNCKS:
			for y_i in MAX_CHUNCKS:
				var load_x = x_i - CHUCK_RADIUS
				var load_y = y_i - CHUCK_RADIUS
				load_section_at(load_x,load_y)
		return
	@warning_ignore("integer_division")
	var x : int = snappedi(Player.current_player.global_position.x,CHUNK_SIZE)/CHUNK_SIZE
	@warning_ignore("integer_division")
	var y : int = snappedi(Player.current_player.global_position.z,CHUNK_SIZE)/CHUNK_SIZE
	var current_chunk := Vector2i(x,y)
	if current_chunk != last_chuck:
		update_chunks(last_chuck,current_chunk)
	last_chuck = current_chunk

func update_chunks(last:Vector2i, current:Vector2i) -> void:
	#moved x positive
	if last.x < current.x:
		#load:
		for i in MAX_CHUNCKS:
			load_section_at(current.x+CHUCK_RADIUS,current.y+i-CHUCK_RADIUS)
		#unload:
			unload_section_at(current.x-(CHUCK_RADIUS+1),current.y+i-CHUCK_RADIUS)
	#moved x negative
	if last.x > current.x:
		#load:
		for i in MAX_CHUNCKS:
			load_section_at(current.x-CHUCK_RADIUS,current.y+i-CHUCK_RADIUS)
		#unload:
			unload_section_at(current.x+(CHUCK_RADIUS+1),current.y+i-CHUCK_RADIUS)
	#moved y positive
	if last.y < current.y:
		#load:
		for i in MAX_CHUNCKS:
			load_section_at(current.x+i-CHUCK_RADIUS,current.y+CHUCK_RADIUS)
		#unload:
			unload_section_at(current.x+i-CHUCK_RADIUS,current.y-(CHUCK_RADIUS+1))
	#moved y negative
	if last.y > current.y:
		#load:
		for i in MAX_CHUNCKS:
			load_section_at(current.x+i-CHUCK_RADIUS,current.y-CHUCK_RADIUS)
		#unload:
			unload_section_at(current.x+i-CHUCK_RADIUS,current.y+(CHUCK_RADIUS+1))

func load_section_at(x:int,y:int):
	var section : Node3D
	if generated_chunks > 81:
		var exit_chance : float = 0.02 if generated_chunks < 250 else 0.04
		if randf() < exit_chance:
			section = preload("res://resources/textures/0/sections/sec_7.tscn").instantiate()
		else:
			section = sections.pick_random().instantiate()
	else:
		section = sections.pick_random().instantiate()
	var rand_deg = 90*(randi()%4)
	section.rotate(Vector3(0,1,0),deg_to_rad(rand_deg))
	$Sections.add_child(section)
	section.global_position = Vector3(x*CHUNK_SIZE,0.0,y*CHUNK_SIZE)
	var key : String = str(x)+","+str(y)
	loaded_sections[key] = section
	generated_chunks += 1

func unload_section_at(x,y):
	var key : String = str(x)+","+str(y)
	if not loaded_sections.has(key):
		printerr("ahhh %s, %s"%[x,y])
		return
	var section : Node3D = loaded_sections[key]
	loaded_sections.erase(key)
	section.queue_free()
