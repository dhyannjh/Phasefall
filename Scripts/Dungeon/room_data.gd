extends Resource

class_name RoomData

@export var difficulty: int = 0
@export var room_type: String = "combat"

@export var room_scene: PackedScene
@export var grid_position: Vector2i

var room_instance: Node2D
