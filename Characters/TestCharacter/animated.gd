extends Node3D

@onready var anim_tree: AnimationTree = $AnimationTree
var state_playback: AnimationNodeStateMachinePlayback

# 🛠️ THE WATCHER VARIABLE
var was_in_attack_state: bool = false

func _ready() -> void:
	# Force tree reboot to clear any C++ null cache
	anim_tree.active = false
	anim_tree.active = true
	state_playback = anim_tree.get("parameters/playback")
	
	# Notice we completely deleted the buggy animation_finished signal connection!

func _process(_delta: float) -> void:
	if not state_playback:
		return
		
	var current_root_node = state_playback.get_current_node()
	var is_action_locked: bool = false
	
	# 1. Check if we are doing a ground attack
	if current_root_node in ["PushKick", "LegSweep", "FlyingKick"]:
		is_action_locked = true
		
	# 2. Check if we are inside the Airborne machine, and specifically on "Landing"
	elif current_root_node == "Airborne":
		# Grab the internal playback controller for the nested machine
		var air_playback = anim_tree.get("parameters/Airborne/playback")
		if air_playback and air_playback.get_current_node() == "Landing":
			is_action_locked = true

	# 3. The Unlocker
	if was_in_attack_state and not is_action_locked:
		var player_physics_body = get_parent()
		if player_physics_body and "state" in player_physics_body:
			player_physics_body.state = player_physics_body.States.IDLE
			
	was_in_attack_state = is_action_locked

func update_locomotion_speed(is_moving: bool) -> void:
	var target_blend: float = 1.0 if is_moving else -1.0
	anim_tree.set("parameters/Locomotion/blend_position", target_blend)

func play_action_state(state_path: String) -> void:
	if not state_playback:
		return
		
	# 📁 ROUTE 1: Nested Sub-Machines (e.g. "Airborne/Falling")
	if "/" in state_path:
		var path_parts = state_path.split("/")
		var root_node = path_parts[0] # "Airborne"
		var sub_node = path_parts[1]  # "Falling"
		
		# Ensure the main tree is actually on the Airborne block first
		if state_playback.get_current_node() != root_node:
			state_playback.travel(root_node)
			
		# Grab the internal playback controller for the nested graph
		var sub_playback = anim_tree.get("parameters/" + root_node + "/playback")
		if sub_playback:
			var current_sub = sub_playback.get_current_node()
			var fading_sub = sub_playback.get_fading_from_node()
			
			# 🛠️ THE NESTED GUARD GATE
			if current_sub == sub_node or fading_sub == sub_node:
				return 
				
			print("playing nested: " + sub_node)
			sub_playback.travel(sub_node)
			
	# 🏠 ROUTE 2: Root Level Nodes (e.g. "Locomotion" or "PushKick")
	else:
		var current_state = state_playback.get_current_node()
		var fading_from = state_playback.get_fading_from_node()
		
		if current_state == state_path or fading_from == state_path:
			return 

		print("playing root: " + state_path)
		state_playback.travel(state_path)
