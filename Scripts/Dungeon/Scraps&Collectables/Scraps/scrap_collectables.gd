extends Area2D

@export var scrap_data: ScrapData
@export var value := 1

var velocity := Vector2.ZERO

@onready var sprite = $AnimatedSprite2D

func _ready():
	if scrap_data:
		sprite.sprite_frames = scrap_data.sprite_frames

	velocity = Vector2(
		randf_range(-80, 80),
		randf_range(-80, 80)
	)

func _physics_process(delta):
	
	sprite.play("main")

	# little bounce/spread effect
	position += velocity * delta

	velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)

	# attract to player
	var player = get_tree().get_first_node_in_group("player")

	if player:
		var dist = global_position.distance_to(player.global_position)

		if dist < 96:
			var dir = global_position.direction_to(player.global_position)

			velocity += dir * 600 * delta

func _on_body_entered(body):

	if body.is_in_group("player"):

		body.add_scrap(value)

		queue_free()
