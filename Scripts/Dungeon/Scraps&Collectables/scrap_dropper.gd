extends Node2D
class_name BreakableBase

@export var max_health := 10
@export var sprite: SpriteFrames
@export var scrap_data: ScrapData
@export var scrap_scene: PackedScene
@export var amount : int = 3

var health := max_health

@warning_ignore("unused_parameter")
func take_damage(damage, knockback = Vector2.ZERO):

	health -= damage

	if health <= 0:
		break_object()

func break_object():
	
	sprite.play("break")
	await sprite.animation_finished

	drop_scrap()

	queue_free()

func drop_scrap():

	for i in amount:

		var scrap = scrap_scene.instantiate()

		scrap.global_position = global_position

		get_tree().current_scene.add_child(scrap)
