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

# --- STATE ---
var base_velocity = Vector2.ZERO
var knockback_vel = Vector2.ZERO
var can_attack = true

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
	handle_actions()
	apply_knockback(delta)
	update_velocity()
	move_and_slide()
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
		else:
			base_velocity.x = move_toward(base_velocity.x, direction * speed, acceleration * air_control * delta)
	else:
		base_velocity.x = move_toward(base_velocity.x, 0, friction * delta)
	
func jump():
	if is_on_floor():
		base_velocity.y = jump_velocity


func stop():
	base_velocity.x = 0


# =========================
# ACTIONS
# =========================
func handle_actions():
	if attack_requested:
		attack()
		attack_requested = false


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
		
	damage_hitbox.knockback = Vector2(200, -100)
	
	print("Enemy X:", global_position.x)
	print("Player X:", ai.player.global_position.x)
	print("Dir:", dir)

	# WINDUP
	can_attack = false
	await get_tree().create_timer(0.1).timeout
	hitbox_shape.visible = true

	# ATTACK
	damage_hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	damage_hitbox.deactivate()

	# COOLDOWN
	await get_tree().create_timer(attack_cooldown).timeout
	hitbox_shape.visible = false
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
	print("Enemy Knockback: ", knockback_vel)


func update_velocity():
	velocity = base_velocity + knockback_vel
	print("enemy Vel: ", velocity)


# =========================
# DAMAGE
# =========================
func take_damage(damage, knockback = Vector2.ZERO):
	health -= damage
	knockback_vel = knockback
	hp_bar.value = health

	print("Enemy Health: ", health)

	if health <= 0:
		print("Enemy Died")
		queue_free()
