extends Node2D

@onready var animated_sprite := $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("burst")
	await animated_sprite.animation_finished
	self.queue_free()
