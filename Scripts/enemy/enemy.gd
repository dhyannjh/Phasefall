# === ENEMY SCRIPT ===

extends CharacterBody2D

@export var team = GLOBAL.team.ENEMY
@export var health = 100

# --- PHYSICS ---
@export var jump_velocity := -300.0
@export var fall_gravity_multiplier := 1.7
@export var knockback_decay := 800.0

# --- MOVEMENT ---
@export var speed := 70.0
@export var acceleration := 550.0
@export var friction := 1500.0
@export var air_control := 0.7

# --- ATTACK ---
@export var attack_cooldown := 0.2
@export var knockback_value := Vector2i(300, -200)
@export var animation_offeset_BA := Vector2i(1, -5)

# --- HITBOX ---
@onready var damage_hitbox: Area2D = $DamageHitbox
@onready var damage_hitbox_dir: AnimationPlayer = $DamageHitbox/AnimationPlayer
@onready var hitbox_shape: Sprite2D = $DamageHitbox/hitboxShape

# --- AI INPUTS ---
var move_input := 0.0
var jump_requested := false
var stop_requested := false
var attack_requested := false
var player_dir := 0

# --- OTHER NODES ---
@onready var ai: Node = $AI
@onready var hp_bar: ProgressBar = $HPBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var land_particles: GPUParticles2D = $GroundParticles/LandParticles
@onready var run_particles: GPUParticles2D = $GroundParticles/RunParticles

var burst_scene = preload("res://Scenes/vfx/attack_burst_1.tscn")

# --- STATE ---
var base_velocity = Vector2.ZERO
var knockback_vel = Vector2.ZERO
var can_attack = true
var is_attacking = false

var was_on_floor = false
var is_now_on_floor = false
var just_landed = false

# --- HITBOX SETTINGS ---
var hitbox_offset := 0
var hitbox_shape_size := 17.3

# =========================
# READY
# =========================
func _ready() -> void:
	damage_hitbox.team = team
	
	# --- AI SETTINGS ---
	ai.detection_range = 1000
	ai.attack_range = 21
	
	# --- HP BAR SETTINGS ---
	
	hp_bar.max_value = health
	hp_bar.value = health
	

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)
	handle_animations(move_input)
	handle_actions(move_input)
	apply_knockback(delta)
	update_velocity()
	move_and_slide()
	do_on_landed()
	#print("MOVE INPUT: ", move_input)
	#print("Players: ", GLOBAL.players.size())


# =========================
# MOVEMENT
# =========================
func handle_movement(delta):
	
	if knockback_vel.length() > 20: return
	
	move(move_input, delta)

	if jump_requested:
		jump()
		jump_requested = false

	if stop_requested:
		stop()
		stop_requested = false


func move(direction: float, delta):
	if direction != 0:
		if is_on_floor():
			base_velocity.x = move_toward(base_velocity.x, direction * speed, acceleration * delta)
			run_particles.emitting = true
		else:
			base_velocity.x = move_toward(base_velocity.x, direction * speed, acceleration * air_control * delta)
			run_particles.emitting = false
	else:
		base_velocity.x = move_toward(base_velocity.x, 0, friction * delta)
		run_particles.emitting = false
	
func jump():
	if is_on_floor():
		base_velocity.y = jump_velocity
		#spawn_burst(0.4)

func stop():
	base_velocity.x = 0


# =========================
# ANIMATIONS
# =========================
func handle_animations(dir):
	
	if is_attacking:
		return
	
	animated_sprite.offset = Vector2i.ZERO
	if not is_on_floor():
		animated_sprite.play("jump")
	elif abs(base_velocity.x) > 5:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

	# Flip
	if dir < 0:
		animated_sprite.flip_h = true
	elif dir > 0:
		animated_sprite.flip_h = false


# =========================
# ACTIONS
# =========================
func handle_actions(dir):
	if attack_requested:
		is_attacking = true
		animated_sprite.offset = animation_offeset_BA * Vector2i(dir, 1)
		if is_on_floor():
			animated_sprite.play("basic_attack_grounded")
		else:
			animated_sprite.play("basic_attack_arial")
		attack()
		attack_requested = false
		await animated_sprite.animation_finished
		is_attacking = false


func attack():
	if not can_attack:
		return

	var dir = -sign(ai.player.global_position.x - global_position.x)
	if dir == 0:
		dir = 1
	#print("player dir: ", player_dir)
	
	if dir == -1:
		damage_hitbox_dir.play("flip_right")
	else:
		damage_hitbox_dir.play("flip_left")
		
	damage_hitbox.knockback = knockback_value
	
	print("Enemy X:", global_position.x)
	print("Player X:", ai.player.global_position.x)
	print("Dir:", dir)

	# WINDUP
	can_attack = false
	await get_tree().create_timer(0.1).timeout
	#hitbox_shape.visible = true

	# ATTACK
	damage_hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	damage_hitbox.deactivate()

	# COOLDOWN
	await get_tree().create_timer(attack_cooldown).timeout
	#hitbox_shape.visible = false
	can_attack = true


# =========================
# PHYSICS
# =========================
func apply_gravity(delta):
	if not is_on_floor():
		if base_velocity.y > 0:
			base_velocity.y += GLOBAL.gravity * fall_gravity_multiplier * delta
		else:
			base_velocity.y += GLOBAL.gravity * delta
	else:
		base_velocity.y = 0


func apply_knockback(delta):
	knockback_vel = knockback_vel.move_toward(Vector2.ZERO, knockback_decay * delta)
	#("Enemy Knockback: ", knockback_vel)


func update_velocity():
	velocity = base_velocity + knockback_vel
	#print("enemy Vel: ", velocity)

# =========================
# SPAWN BURST
# =========================
func spawn_burst(trans):
	var burst = burst_scene.instantiate()
	
	# --- Position burst ---
	burst.global_position = global_position + Vector2(0, 4)
	burst.z_index = 80
	burst.scale.x = -sign(move_input) if move_input != 0 else 1
	burst.modulate.a = trans
	
	get_tree().current_scene.add_child(burst)


# =========================
# CHECK JUST LANDED
# =========================
func do_on_landed():
	
	is_now_on_floor = is_on_floor()
	
	if not was_on_floor and is_now_on_floor:
		#print("Enemy Just Landed")
		land_particles.restart()
		just_landed = true
		
	was_on_floor = is_now_on_floor


# =========================
# DAMAGE
# =========================
func take_damage(damage, knockback = Vector2.ZERO):
	health -= damage
	knockback_vel = knockback
	hp_bar.value = health
	
	# --- SCREEN SHAKE ---
	get_viewport().get_camera_2d().shake(2)

	#print("Enemy Health: ", health)

	if health <= 0:
		print("Enemy Died")
		queue_free()
