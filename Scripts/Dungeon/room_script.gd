extends Node2D

@export var room_grid_position : Vector2i
@export var room_theme := "industrial"

var active := false

func activate():

	if active:
		return

	active = true

	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate():

	if !active:
		return

	active = false

	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
