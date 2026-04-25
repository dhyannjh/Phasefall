#DMAGE HITBOX SCRIPT

extends Area2D

@export var damage = 10
@export var knockback = Vector2(400, -200)
var team = ""

var already_hit = []

func activate():
	already_hit.clear()
	monitoring = true

func deactivate():
	monitoring = false

func _ready() -> void:
	monitoring = false

func _on_body_entered(body: Node2D) -> void:
	print("hit something")
	
	#CHECK OF BOBY IS DAMAGEABLE
	if not body.has_method("take_damage"):
		return
	
	if body in already_hit:
		return
	
	if body.team == team:
		return
	
	already_hit.append(body)
	
	var dir = 1
	if global_position.x < body.global_position.x:
		dir = 1
	else:
		dir = -1

	var final_knockback = Vector2(knockback.x * dir, knockback.y)
	
	body.take_damage(damage, final_knockback)
