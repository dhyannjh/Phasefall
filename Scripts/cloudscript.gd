extends Node2D

@export var cloud_scenes: Array[PackedScene]
@export var cloud_count := 8

@export var speed := 1.0
@export var spawn_width := 2000.0
@export var max_spawn_height := -30.0
@export var min_spawn_height := -30.0

@export var left_limit := -1000.0
@export var right_limit := 2000.0

func _ready():
	spawn_clouds()

func spawn_clouds():
	for i in range(cloud_count):
		var cloud = cloud_scenes.pick_random().instantiate()
		
		cloud.position = Vector2(
			randf_range(left_limit, right_limit),
			randf_range(min_spawn_height, max_spawn_height)
		)
		
		add_child(cloud)

func _process(delta):
	for cloud in get_children():
		cloud.position.x += speed * delta
		
		if cloud.position.x > right_limit:
			cloud.position.x = left_limit
			cloud.position.y = randf_range(min_spawn_height, max_spawn_height)
