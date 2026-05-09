extends Node2D

@export var room_grid_position : Vector2i
@export var room_theme := "industrial"

var active := false


func _ready():
	deactivate()

func activate():

	if active:
		return

	active = true

	#visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)


func deactivate():

	if !active:
		return

	active = false

	#visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_physics_process(false)
