extends Node2D

@export var grid_size: Vector2i = Vector2i(4, 4)
@export var room_spacing: Vector2 = Vector2(1024, 768)

# --- ROOMS ---
@export var medium_rooms: Array[PackedScene]
@export var easy_rooms: Array[PackedScene]
@export var hard_rooms: Array[PackedScene]

var grid = []
var player_pos = Vector2i(0, 0)

# =========================
# ON START
# =========================
func _ready() -> void:
	generate_grid()
	build_dungeon()


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
	
	if difficulty < 2:
		return easy_rooms.pick_random()
		
	elif difficulty < 5:
		return medium_rooms.pick_random()
		
	else:
		return hard_rooms.pick_random()


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
	return Vector2i(
		floor(player_world_pos.x / room_spacing.x),
		floor(player_world_pos.y / room_spacing.y)
	)


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

			add_child(instance)
