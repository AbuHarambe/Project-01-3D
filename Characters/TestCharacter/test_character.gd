extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_force: float = 16.0
enum States {IDLE, RUNNING, JUMPING, FALLING, ATTACK, DASH, LOCKED}
var state: States = States.IDLE
# Using Godot's project settings gravity default for 3D
@export var gravity: float = 30.0

func _process(delta: float) -> void:
	handle_horizontal_movement()
	apply_gravity(delta)
	handle_jump()

	# Move using Godot's built-in 3D physics solver
	move_and_slide()
	
	# CRITICAL FOR 2D PLATFORM FIGHTERS:
	# Force the Z position and Z velocity to stay at absolute zero
	global_position.z = 0.0
	velocity.z = 0.0
	
	#State Machine
	print("velocity.x = " + str(velocity.x))
	if state == States.LOCKED:
		return
	else:
		if velocity.x != 0 and is_on_floor() and state != States.ATTACK:
			state = States.RUNNING
			print("should be running")
			
		elif velocity.x == 0 and is_on_floor():
			state = States.IDLE
			
	handle_animation()
	

func handle_horizontal_movement() -> void:
	# Get raw horizontal input using your existing InputMap actions
	var input_dir := Input.get_axis("move_left", "move_right")
	
	# Apply strictly to the X axis
	velocity.x = input_dir * move_speed

func apply_gravity(delta: float) -> void:
	# is_on_floor() works out-of-the-box for CharacterBody3D
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		# Small reset to stop downward velocity compounding on the floor
		velocity.y = 0.0

func handle_jump() -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force

func handle_animation():
	var dictionary = {States.IDLE:"breathing_idle", States.RUNNING:"running"}
	var dictOut = dictionary[state]
	print(state)
	$Base/AnimationPlayer.play(dictOut)
	print("playing: " + dictOut)
	return
