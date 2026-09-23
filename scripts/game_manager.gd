extends Node

const EXP_LEVELS := [0, 0, 50, 130, 240, 380]
var enemies: Dictionary = {}
var player_level := 1
var current_exp := 0
var max_hp := 100
var current_hp := 100
var attack := 22
var defense := 8
var calories := 700
var motivation := 80
var fight_count := 0
var fight_win_count := 0
var eat_count := 0
var call_count := 0
var completed: Dictionary = {}
var player_position := Vector2(260, 364)
var enemy_id := ""
var encounter_id := ""

func _ready() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if file:
		enemies = JSON.parse_string(file.get_as_text())

func reset() -> void:
	player_level = 1
	current_exp = 0
	max_hp = 100
	current_hp = 100
	attack = 22
	defense = 8
	calories = 700
	motivation = 80
	fight_count = 0
	fight_win_count = 0
	eat_count = 0
	call_count = 0
	completed.clear()
	player_position = Vector2(260, 364)
	enemy_id = ""
	encounter_id = ""

func modifier() -> float:
	return 0.5 + motivation / 200.0

func gain_exp(amount: int) -> Array[int]:
	current_exp += amount
	var levels: Array[int] = []
	while player_level < 5 and current_exp >= EXP_LEVELS[player_level + 1]:
		player_level += 1
		max_hp += 12
		attack += 4
		defense += 2
		current_hp = mini(max_hp, current_hp + 20)
		levels.append(player_level)
	return levels

func failure() -> String:
	if current_hp <= 0:
		return "hp"
	if calories >= 1600:
		return "calories"
	if motivation <= 10:
		return "motivation"
	return ""
