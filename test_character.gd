extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_force: float = 16.0

# Using Godot's project settings gravity default for 3D
@export var gravity: float = 30.0

func _physics_process(delta: float) -> void:
	handle_horizontal_movement()
	apply_gravity(delta)
	handle_jump()

	# Move using Godot's built-in 3D physics solver
	move_and_slide()
	
	# CRITICAL FOR 2D PLATFORM FIGHTERS:
	# Force the Z position and Z velocity to stay at absolute zero
	global_position.z = 0.0
	velocity.z = 0.0

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
