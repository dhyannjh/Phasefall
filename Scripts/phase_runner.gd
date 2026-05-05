extends CharacterBody2D

@export var team = GLOBAL.team.PLAYER

# --- BASIC ATTACK SETTINGS ---
@export var cooldown := 0.2
@export var damage := 10
@export var knockback_decay := 800.0
@export var knockback_value := Vector2i(300, -200)
@export var animation_offeset_BA := Vector2i(1, -5)

# --- MOVEMENT SETTINGS ---
@export var speed := 100.0
@export var acceleration := 600.0
@export var friction := 1500.0

# --- JUMP SETTINGS ---
@export var jump_velocity := -350.0
@export var fall_gravity_multiplier := 1.0
@export var air_control := 0.7

# --- COYOTE + BUFFER ---
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.05

# --- STATE ---
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var can_attack := true
var is_attacking := false

var base_velocity = Vector2.ZERO
var knockback_vel = Vector2.ZERO

var health = 100

var was_on_floor = false
var is_now_on_floor = false
var just_landed = false

# --- REFERENCES ---
@onready var damage_hitbox: Area2D = $DamageHitbox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_hitbox_dir: AnimationPlayer = $DamageHitbox/AnimationPlayer
@onready var hitbox_shape: Sprite2D = $DamageHitbox/hitboxShape
@onready var hp_bar: ProgressBar = $HPBar

@onready var land_particles: GPUParticles2D = $GroundParticles/LandParticles
@onready var run_particles: GPUParticles2D = $GroundParticles/RunParticles

var burst_scene = preload("res://Scenes/vfx/attack_burst_1.tscn")

# --- INPUT CACHE (future AI-ready) ---
var move_input := 0.0
var jump_pressed := false
var jump_released := false
var attack_pressed := false


# =========================
# READY
# =========================
func _ready() -> void:
	GLOBAL.register_player(self)
	damage_hitbox.team = team
	
	# --- HP BAR SETTINGS ---
	hp_bar.max_value = health
	hp_bar.value = health


# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):
	read_input()
	handle_movement(delta)
	apply_gravity(delta)
	handle_jump(delta)
	handle_attack(move_input)
	apply_knockback(delta)
	update_velocity()
	handle_animations(move_input)
	move_and_slide()
	do_on_landed()
	
	#TEMP -------------------------------
	if Input.is_action_just_pressed("ui_undo"):
		get_tree().reload_current_scene()


# =========================
# INPUT
# =========================
func read_input():
	move_input = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	attack_pressed = Input.is_action_just_pressed("M1")


# =========================
# MOVEMENT
# =========================
func handle_movement(delta):
	
	var controll = 1
	
	if knockback_vel.length() > 20:
		controll = 0.3
	
	if move_input != 0:
		if is_on_floor():
			base_velocity.x = move_toward(
				base_velocity.x, 
				move_input * speed, acceleration * controll * delta
				)
			run_particles.emitting = true
				
		else:
			base_velocity.x = move_toward(
				base_velocity.x,
				move_input * speed, acceleration * air_control * controll * delta
				)
			run_particles.emitting = false
	else:
		base_velocity.x = move_toward(base_velocity.x, 0, friction * delta)
		run_particles.emitting = false


# =========================
# GRAVITY
# =========================
func apply_gravity(delta):
	if not is_on_floor():
		if base_velocity.y > 0:
			base_velocity.y += GLOBAL.gravity * fall_gravity_multiplier * delta
		else:
			base_velocity.y += GLOBAL.gravity * delta
	else:
		base_velocity.y = 0


# =========================
# JUMP
# =========================
func handle_jump(delta):
	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Jump buffer
	if jump_pressed:
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0 and coyote_timer > 0:
		base_velocity.y = jump_velocity
		#spawn_burst(0.4)
		jump_buffer_timer = 0
		coyote_timer = 0

	# Short hop
	if jump_released and base_velocity.y < 0:
		base_velocity.y *= 0.5
		
	if is_on_ceiling():
		base_velocity.y = 70
		get_viewport().get_camera_2d().shake(0.7)


# =========================
# ATTACK
# =========================
func handle_attack(dir):
	if attack_pressed and can_attack:
		animated_sprite.offset = animation_offeset_BA * Vector2i(dir, 1)
		if is_on_floor():
			animated_sprite.play("basic_attack_grounded")
		else:
			animated_sprite.play("basic_attack_arial")
		is_attacking = true
		attack()
		await animated_sprite.animation_finished
		is_attacking = false

func attack():

	var dir = sign(base_velocity.x)
	if dir == 0:
		dir = -1 if animated_sprite.flip_h else 1

	damage_hitbox.knockback = knockback_value
	damage_hitbox.damage = damage

	if dir > 0:
		damage_hitbox_dir.play("facing_right")
	else:
		damage_hitbox_dir.play("facing_left")

	can_attack = false
	#hitbox_shape.visible = true

	# ATTACK
	damage_hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	damage_hitbox.deactivate()

	# COOLDOWN
	await get_tree().create_timer(cooldown).timeout
	#hitbox_shape.visible = false
	can_attack = true
	is_attacking = false


# =========================
# KNOCKBACK
# =========================
func apply_knockback(delta):
	knockback_vel = knockback_vel.move_toward(Vector2.ZERO, knockback_decay * delta)
	#print("knockback: ", knockback_vel)


# =========================
# FINAL VELOCITY
# =========================
func update_velocity():
	velocity = base_velocity + knockback_vel
	#print(velocity)


# =========================
# ANIMATIONS (FIXED)
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
# CHECK JUST LANDED
# =========================
func do_on_landed():
	
	is_now_on_floor = is_on_floor()
	
	if not was_on_floor and is_now_on_floor:
		#print("Just Landed")
		land_particles.restart()
		just_landed = true
		
	was_on_floor = is_now_on_floor


'''
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
'''


# =========================
# DAMAGE
# =========================
@warning_ignore("shadowed_variable")
func take_damage(damage, knockback = Vector2.ZERO):
	health -= damage
	knockback_vel = knockback
	
	# --- SCREEN SHAKE ---
	get_viewport().get_camera_2d().shake(2)

	print("Player Health: ", health)
	hp_bar.value = health

	if health <= 0:
		print("Player Died")
		get_tree().reload_current_scene()
