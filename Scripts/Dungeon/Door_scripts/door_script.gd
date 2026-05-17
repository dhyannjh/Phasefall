extends Node2D
class_name DoorBase

signal opened
signal closed

enum DoorState {
	OPEN,
	CLOSED
}

var state = DoorState.CLOSED

@onready var collision = $CollisionShape2D


func open():
	if state == DoorState.OPEN:
		return

	state = DoorState.OPEN

	collision.disabled = true

	play_open_visuals()

	opened.emit()


func close():
	if state == DoorState.CLOSED:
		return

	state = DoorState.CLOSED

	collision.disabled = false

	play_close_visuals()

	closed.emit()


# --- INHERITED SCENE SCRIPT FOR REAL DOORS --- 

'''

extends door_base

@onready var sprite = $Visuals/AnimatedSprite2D


func play_open_visuals():
    sprite.play("open")


func play_close_visuals():
    sprite.play("close")

'''


# --- VISUAL FUNCTIONS ---
# Child doors will replace these

func play_open_visuals():
	pass


func play_close_visuals():
	pass
