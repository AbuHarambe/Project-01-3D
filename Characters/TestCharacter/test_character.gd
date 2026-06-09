extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_force: float = 16.0
@export var gravity: float = 30.0

var input_dir: float = 0.0

enum States {IDLE, RUNNING, JUMPING, FALLING, LANDING, ATTACK, DASH, LOCKED}
var state: States = States.IDLE

@onready var animated_character = $Animated

func _physics_process(delta: float) -> void:
	input_dir = Input.get_axis("move_left", "move_right")

	# Apply gravity BEFORE jumping! 
	apply_gravity(delta)

	if state != States.LOCKED:
		handle_jump()
		handle_horizontal_movement()
	else:
		velocity.x = 0.0 
		
	move_and_slide()
	
	global_position.z = 0.0
	velocity.z = 0.0
	
	update_gameplay_state()
	handle_visual_updates()

func handle_horizontal_movement() -> void:
	if state == States.ATTACK and is_on_floor():
		velocity.x = 0.0
		return
		
	velocity.x = input_dir * move_speed
	
	# 🔄 INSTANT ROTATION LOGIC
	# Only rotate if the player is actively pressing a direction
	if input_dir > 0:
		animated_character.rotation_degrees.y = 90.0
	elif input_dir < 0:
		animated_character.rotation_degrees.y = -90.0

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

func handle_jump() -> void:
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		state = States.JUMPING
		animated_character.play_action_state("Airborne/Jumping")

func update_gameplay_state() -> void:
	# 1. Combat Input Checks
	if Input.is_action_just_pressed("light_attack") and Input.is_action_pressed("down") and is_on_floor():
		state = States.ATTACK
		animated_character.play_action_state("LegSweep")
		
	elif Input.is_action_just_pressed("light_attack") and is_on_floor():
		state = States.ATTACK
		animated_character.play_action_state("PushKick")
		
	elif Input.is_action_just_pressed("heavy_attack") and input_dir != 0 and is_on_floor():
		state = States.ATTACK
		animated_character.play_action_state("FlyingKick")
		
	# 2. Airborne State Checks
	elif not is_on_floor() and state != States.ATTACK:
		if velocity.y > 0.0:
			if state != States.JUMPING:
				state = States.JUMPING
				animated_character.play_action_state("Airborne/Jumping")
		else:
			if state != States.FALLING:
				state = States.FALLING
				animated_character.play_action_state("Airborne/Falling")
				
	# 3. Ground Landing Reset 
	elif is_on_floor() and state != States.ATTACK and state != States.LOCKED:
		if state == States.FALLING:
			state = States.LANDING
			# Ensure the slash is here so it routes to the sub-machine!
			animated_character.play_action_state("Airborne/Landing")
			velocity.x = 0.0

func handle_visual_updates() -> void:
	# Pass a simple boolean (true if moving, false if stopped)
	var is_moving: bool = velocity.x != 0.0
	animated_character.update_locomotion_speed(is_moving)
	
	if state == States.ATTACK or state == States.JUMPING or state == States.FALLING:
		return
		
	if is_on_floor():
		animated_character.play_action_state("Locomotion")
