extends Node

# --- GLOBAL VALUES ---
const max_health = 100
@export var gravity := 1100.0
enum team {
	PLAYER,
	ENEMY,
}

var players = []
var scores = {}

func register_player(player):
	players.append(player)
	scores[player] = 0
