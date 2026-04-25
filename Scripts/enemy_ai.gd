# === ENEMY AI SCRIPT ===

extends Node

@export var enemy: CharacterBody2D
@export var detection_range := 1000.0
@export var attack_range := 20.0

# --- RAYCAST VARS ---
@onready var ground_ray: RayCast2D
@onready var wall_ray: RayCast2D 
var ground_ray_length := 0.0
var wall_ray_length := 0.0

# =========================
# STATES
# =========================
enum State {
	IDLE,
	CHASE,
	ATTACK
}

var current_state: State = State.IDLE
var player = null


# =========================
# FIND CLOSEST PLAYER
# =========================
func get_closest_player():
	var closest = null
	var min_dist = INF
	
	for p in GLOBAL.players:
		if not is_instance_valid(p):
			continue
			
		var d = enemy.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			closest = p
	
	return closest


# =========================
# STATE BEHAVIOUR
# =========================

func do_idle():
	enemy.move_input = 0
	enemy.attack_requested = false

func do_chase():
	var dx = player.global_position.x - enemy.global_position.x
	var dir = sign(dx)
	var dy = player.global_position.y - enemy.global_position.y

	# If enemy is above player and too close → move away / jump
	if abs(dx) < 16 and dy > 0:
		enemy.jump_requested = true
		enemy.move_input = dir * 4 # move away slightly
		return

	# Fix ONLY zero case
	if dir == 0:
		dir = 1 if player.global_position.x > enemy.global_position.x else -1

	@warning_ignore("unused_variable")
	var distance = enemy.global_position.distance_to(player.global_position)

	# Stop when close enough
	#if distance <= attack_range:
	#	enemy.move_input = 0
	#	return

	# Prevent falling
	if not ground_ray.is_colliding():
		enemy.move_input = dir * 0.2
		return

	# Jump over walls (NOT player)
	if wall_ray.is_colliding():
		var collider = wall_ray.get_collider()
		var is_player = collider == player or collider.get_parent() == player

		if not is_player:
			enemy.jump_requested = true

	enemy.move_input = dir

func do_attack():
	var distance = enemy.global_position.distance_to(player.global_position)

	# If we somehow can't actually hit, go back to chase
	if distance > attack_range:
		current_state = State.CHASE
		return

	enemy.move_input = 0
	enemy.attack_requested = true


# =========================
# GET DIRECTION TO PLAYER
# =========================
func get_player_dir():
	
	if player == null:
		return
		
	'''
	enemy.player_dir = sign(player.global_position.x - enemy.global_position.x)
	'''
	#'''
	var player_to_right = enemy.global_position.x < player.global_position.x
	
	if player_to_right:
		enemy.player_dir = -1
	else:
		enemy.player_dir = 1
	#print("player dir: ", enemy.player_dir)
	#print("player to right: ", player_to_right)
	#'''


# =========================
# STATE TRANSITIONS
# =========================
func update_state():
	if player == null:
		current_state = State.IDLE
		return
	
	
	var distance = enemy.global_position.distance_to(player.global_position)
	@warning_ignore("unused_variable")
	var dx = abs(player.global_position.x - enemy.global_position.x)
	var dy = abs(player.global_position.y - enemy.global_position.y)


	if distance > detection_range:
		current_state = State.IDLE
	elif distance < attack_range - 1 and abs(dy) < 5:
		current_state = State.ATTACK
	else:
		current_state = State.CHASE


# =========================
# READY
# =========================
func _ready():
	if enemy == null:
		enemy = get_parent() as CharacterBody2D
		
	ground_ray = enemy.get_node_or_null("RayCasts/GroundRayCast")
	wall_ray = enemy.get_node_or_null("RayCasts/WallRayCast")
	
	if ground_ray == null:
		push_error("Ground ray not found!")

	if wall_ray == null:
		push_error("Wall ray not found!")
	
	if enemy == null:
		push_error("AI: Enemy not assigned!")
		
	ground_ray_length = abs(ground_ray.target_position.x)
	wall_ray_length = abs(wall_ray.target_position.x)


# =========================
# RAYCAST FLIP
# =========================
func update_rays():
	if player == null:
		return
	
	var dir = sign(player.global_position.x - enemy.global_position.x)
	if dir == 0:
		return
	
	ground_ray.target_position.x = ground_ray_length * dir
	wall_ray.target_position.x = wall_ray_length * dir

# =========================
# MAIN LOOP
# =========================
@warning_ignore("unused_parameter")
func _physics_process(delta):
	
	ground_ray.force_raycast_update()
	wall_ray.force_raycast_update()
	
	player = get_closest_player()
	
	get_player_dir()
	update_state()
	update_rays()
	
	match current_state:
		State.IDLE:
			do_idle()
		State.CHASE:
			do_chase()
		State.ATTACK:
			do_attack()
			
	#print("state: ", current_state)
	#print("Enemy: ", enemy.global_position)
	#print("Ray: ", ground_ray.global_position)
