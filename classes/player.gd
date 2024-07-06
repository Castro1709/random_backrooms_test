extends CharacterBody3D


class_name Player

static var current_player : Player = null

const WALK_SPEED = 2.5
const RUN_SPEED = 6.5
const CROUCH_SPEED = 1.0
const JUMP_VELOCITY = 4.5
const MAX_STAMINA = 3000
const MAX_OVER_STAMINA = 900
const STAMINA_PASS_OUT = -1300

signal interacted()

var capturing_mouse : bool = false
var sensitivity : float = 0.003
## current speed that the player has
var speed = 0.0
var is_crouching : bool = false
var stamina : int = 3000
var over_stamina : int = 900
var pass_out : bool = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not pass_out:
		# Handle jump.
		if Input.is_action_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var target_speed : float = WALK_SPEED
		if Input.is_action_pressed("ui_shift") and stamina > 0:
			stamina -= 2
			target_speed = RUN_SPEED
			if stamina <= 0:
				stamina = -300 if over_stamina >= -600 else -600
			## count the over use of stamina
			if stamina <= MAX_OVER_STAMINA:
				over_stamina -= 2
				if over_stamina <= STAMINA_PASS_OUT:
					pass_out = true
					var tween := create_tween()
					tween.set_ease(Tween.EASE_IN_OUT)
					tween.tween_property($Camera3D,"rotation:z",deg_to_rad(75),0.6)
		else:
			if stamina == -2:
				stamina += 300
			if stamina < MAX_STAMINA:
				stamina += 1
			if stamina >= MAX_OVER_STAMINA and over_stamina < MAX_OVER_STAMINA:
				over_stamina += 1
		target_speed = CROUCH_SPEED if Input.is_action_pressed("ui_control") else target_speed
		is_crouching = Input.is_action_pressed("ui_control")
		if direction:
			velocity.x = direction.x * target_speed
			velocity.z = direction.z * target_speed
		else:
			velocity.x = move_toward(velocity.x, 0, target_speed)
			velocity.z = move_toward(velocity.z, 0, target_speed)
	else:
		velocity.x = 0
		velocity.z = 0
	speed = Vector2(velocity.x,velocity.z).length()
	_update_up_stairs_ray()
	move_and_slide()
	_process_stairs_down()

var _was_on_floor_last_frame := false
var _stairs_snapped_down_last_frame := false
const STAIRS_MAX_STEO_DOWN := -0.35
func _process_stairs_down() -> void:
	_stairs_snapped_down_last_frame = false
	if ! is_on_floor() and velocity.y <=0 and (_was_on_floor_last_frame or _stairs_snapped_down_last_frame):
		var test_result := PhysicsTestMotionResult3D.new()
		var test_params := PhysicsTestMotionParameters3D.new()
		test_params.from = self.global_transform
		test_params.motion = Vector3(0,STAIRS_MAX_STEO_DOWN,0)
		if PhysicsServer3D.body_test_motion(self.get_rid(),test_params,test_result):
			self.position.y += test_result.get_travel().y
			apply_floor_snap()
			_stairs_snapped_down_last_frame = true
	_was_on_floor_last_frame = is_on_floor()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("ui_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and not pass_out:
		rotate_y(-event.relative.x*sensitivity)
		$Camera3D.rotate_x(-event.relative.y*sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2.0, PI/2.0)
	
	
	if %InteractionRayCast.is_colliding():
		var obj = %InteractionRayCast.get_collider()
		if obj is InteractiveZone and not obj.used:
			if %AlertBox.modulate.a < 0.01:
				%AlertBox.modulate.a = 1.0
				interaction_message(obj.hover_message)
			if Input.is_action_just_pressed("ui_right_click"):
				interacted.emit(obj)
		else:
			%AlertBox.modulate.a = 0.0
	else:
		%AlertBox.modulate.a = 0.0

func _ready() -> void:
	current_player = self

@onready
var _separation_ray_distance = absf(%StairsUpRayF.position.z)
var _last_xz_vel := Vector3()
func _update_up_stairs_ray() -> void:
	var xz_vel := Vector3(1,0,1) * velocity
	if xz_vel.length() <0.1:
		xz_vel = _last_xz_vel
	else:
		_last_xz_vel = xz_vel
	var f_ray_pos : Vector3 = xz_vel.normalized() * _separation_ray_distance
	$StairsUpRayF.global_position.x = self.global_position.x + f_ray_pos.x
	$StairsUpRayF.global_position.z = self.global_position.z + f_ray_pos.z
	
	var r_ray_pos : Vector3 = f_ray_pos.rotated(Vector3(0,1,0),deg_to_rad(50))
	$StairsUpRayR.global_position.x = self.global_position.x + r_ray_pos.x
	$StairsUpRayR.global_position.z = self.global_position.z + r_ray_pos.z
	
	var l_ray_pos : Vector3 = f_ray_pos.rotated(Vector3(0,1,0),deg_to_rad(-50))
	$StairsUpRayL.global_position.x = self.global_position.x + l_ray_pos.x
	$StairsUpRayL.global_position.z = self.global_position.z + l_ray_pos.z
	#Prevent climbing walls:
	var max_slope_ang_dot : float = Vector3(0,1,0).rotated(Vector3(1.0,0,0), self.floor_max_angle).dot(Vector3(0,1,0))
	%ClimbRayPreventF.force_raycast_update()
	%ClimbRayPreventR.force_raycast_update()
	%ClimbRayPreventL.force_raycast_update()
	var any_too_steep = false
	if %ClimbRayPreventF.is_colliding() and %ClimbRayPreventF.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if %ClimbRayPreventL.is_colliding() and %ClimbRayPreventL.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if %ClimbRayPreventR.is_colliding() and %ClimbRayPreventR.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	%StairsUpRayF.disabled = any_too_steep
	%StairsUpRayR.disabled = any_too_steep
	%StairsUpRayL.disabled = any_too_steep


const INVENTORY_MAX_VOLUME = 100
const INVENTORY_MAX_WEIGHT = 40000
## keys are item ID and the content is a Item Class
var inventory : Dictionary = {}

## add an item to the inventory
func add_item(item:Item) -> void:
	if inventory.has(item.id):
		var prev_item : Item = inventory[item.id]
		prev_item.amount += item.amount
	else:
		inventory[item.id] = item

enum CanAddItemResult {
	OK,
	FailedTooHeavy,
	FailedTooBig
	}

func can_add_item(item:Item) -> CanAddItemResult:
	var inventory_weight = get_inventory_weight()
	if (item.get_weight() + inventory_weight) > INVENTORY_MAX_WEIGHT:
		return CanAddItemResult.FailedTooHeavy
	var inventory_volume = get_inventory_volume()
	if (item.get_volume() + inventory_volume) > INVENTORY_MAX_VOLUME:
		return CanAddItemResult.FailedTooBig
	return CanAddItemResult.OK

func get_inventory_weight() -> int:
	var total := 0
	for id : int in inventory:
		var item : Item = inventory[id]
		total += item.get_weight()
	return total

func get_inventory_volume() -> int:
	var total := 0
	for id : int in inventory:
		var item : Item = inventory[id]
		total += item.get_volume()
	return total

func interaction_message(message:String, show_click:bool=true,fade_out:bool=false) -> void:
	%AlertBox.modulate.a = 1.0
	%KeyButton.visible = show_click
	%Alert.text = message
	if fade_out:
		var timer := Timer.new()
		timer.wait_time = 1.0
		add_child(timer)
		timer.start()
		await timer.timeout
		timer.queue_free()
		var tween := create_tween()
		tween.tween_property(%AlertBox,"modulate:a",0.0,1.0)

func hide_interaction_message() -> void:
	%AlertBox.modulate.a = 0.0
