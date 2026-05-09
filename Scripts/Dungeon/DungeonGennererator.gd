extends Node2D

@export var grid_size: Vector2i = Vector2i(4, 4)
@export var room_spacing: Vector2 = Vector2(512, 512)

# --- ROOMS ---
@export var medium_rooms: Array[PackedScene]
@export var easy_rooms: Array[PackedScene]
@export var hard_rooms: Array[PackedScene]

# --- PLAYER ---
@onready var player = get_tree().get_first_node_in_group("player")

var grid = []
var player_pos = Vector2i(0, 0)
var last_room := Vector2i(-999, -999)

var used_rooms := []
@export var allow_duplicates := false

# =========================
# ON START
# =========================
func _ready() -> void:
	generate_grid()
	build_dungeon()


# =========================
# LOOP
# =========================
func _physics_process(delta):

	if player:
		
		var current_room = get_player_grid_pos(player.global_position)
		
		if current_room != last_room:
			last_room = current_room
			update_active_rooms(player.global_position)


# =========================
# GENERATE GRID
# =========================
func generate_grid():
	grid.clear()

	for y in range(grid_size.y):
		var row = []
		
		for x in range(grid_size.x):
			var room = RoomData.new()
			room.grid_position = Vector2i(x, y)

			# Difficulty based on position (IMPORTANT)
			room.difficulty = x + y
			
			room.room_scene = get_random_room(room.difficulty)
			
			row.append(room)
		
		grid.append(row)

	print_grid_debug()

func get_random_room(difficulty: int) -> PackedScene:

	var room_pool: Array[PackedScene]

	# Select difficulty pool
	if difficulty < 2:
		room_pool = easy_rooms

	elif difficulty < 5:
		room_pool = medium_rooms

	else:
		room_pool = hard_rooms

	# Filter duplicates
	var possible_rooms: Array[PackedScene] = []

	for room in room_pool:
		if allow_duplicates or room not in used_rooms:
			possible_rooms.append(room)

	# Fallback if exhausted
	if possible_rooms.is_empty():

		print("No unique rooms left in pool.")

		if allow_duplicates:
			possible_rooms = room_pool
		else:
			used_rooms.clear()
			possible_rooms = room_pool

	# Pick room
	var selected = possible_rooms.pick_random()

	# Save used room
	if not allow_duplicates:
		used_rooms.append(selected)

	return selected


# =========================
# DEGUG
# =========================
func print_grid_debug():
	
	for row in grid:
		var line = " "
		for room in row:
			line += str(room.difficulty) + " "
		print(line)


# =========================
# UTILITY
# =========================
func get_room(pos: Vector2i) -> RoomData:
	return grid[pos.y][pos.x]

func get_player_grid_pos(player_world_pos: Vector2) -> Vector2i:

	var grid_x = clamp(
		floor(player_world_pos.x / room_spacing.x),
		0,
		grid_size.x - 1
	)

	var grid_y = clamp(
		floor(player_world_pos.y / room_spacing.y),
		0,
		grid_size.y - 1
	)

	return Vector2i(grid_x, grid_y)


# =========================
# BUILD DUNGEON
# =========================
func build_dungeon():

	for row in grid:
		for room in row:

			var instance = room.room_scene.instantiate()

			instance.position = Vector2(
				room.grid_position.x * room_spacing.x,
				room.grid_position.y * room_spacing.y
			)

			# IMPORTANT
			instance.room_grid_position = room.grid_position

			$"../Rooms".add_child(instance)

			# Save reference
			room.room_instance = instance


# =========================
# ACTIVATE OR DEACTIVATE
# =========================
func update_active_rooms(player_world_pos: Vector2):

	var current_room = get_player_grid_pos(player_world_pos)

	for row in grid:
		for room in row:
			
			var dx = abs(room.grid_position.x - current_room.x)
			var dy = abs(room.grid_position.y - current_room.y)
			
			var active = dx <= 1 and dy <= 1

			if active:
				room.room_instance.activate()
			else:
				room.room_instance.deactivate()
