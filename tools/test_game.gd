extends SceneTree

const ROUTE := ["donut","cake","karaage","burger","pizza","parfait","ramen","final"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	main.muted = true
	root.add_child(main)
	var game: Node = root.get_node("Game")
	seed(0)
	var results := []
	for plan in [
		[1,1,1,1,1,1,1,1],
		[1,1,2,1,2,1,1,1],
		[1,1,2,1,3,1,2,1],
		[2,2,2,2,2,2,2,2],
		[3,3,3,3,3,3,3,3],
	]:
		main._start_game()
		var turns := 0
		var checkpoints := []
		for i in range(ROUTE.size()):
			if main.screen == "game_over": break
			game.enemy_id = ROUTE[i]
			game.encounter_id = "encounter_%02d" % (i+1)
			main._start_battle()
			var cmd: int = plan[i]
			while main.screen == "battle" and not main.battle_finished and turns < 100:
				main._battle_command(cmd)
				turns += 1
			if main.battle_finished:
				main.anim_time = 0; main._finish_battle()
			checkpoints.append([ROUTE[i],game.current_hp,game.max_hp,game.player_level,game.motivation])
		if main.screen == "field":
			game.player_position.x = 2425
			main._check_encounter(2400)
		results.append({"plan":plan,"screen":main.screen,"level":game.player_level,"hp":game.current_hp,"calories":game.calories,"motivation":game.motivation,"battles":game.fight_count,"checkpoints":checkpoints})
	print(JSON.stringify(results))
	if results[0].screen != "station" or results[1].screen != "station" or results[2].screen != "station" or results[3].screen != "game_over" or results[4].screen != "game_over":
		printerr("Balance scenarios failed")
		quit(1)
		return
	for check in [
		{"reason":"hp","hp":1,"calories":700,"motivation":80,"command":1},
		{"reason":"calories","hp":100,"calories":1500,"motivation":80,"command":2},
		{"reason":"motivation","hp":100,"calories":700,"motivation":12,"command":3},
	]:
		main._start_game()
		game.current_hp = check.hp
		game.calories = check.calories
		game.motivation = check.motivation
		game.enemy_id = "donut"
		game.encounter_id = "encounter_01"
		main._start_battle()
		main._battle_command(check.command)
		if main.screen != "game_over" or main.game_over_reason != check.reason:
			printerr("Failed game over route: ",check.reason)
			quit(1)
			return
	main._start_game()
	main._advance_walk(0.15)
	if game.player_position.x <= 260 or is_equal_approx(game.player_position.y,365): return _fail("Automatic meandering walk failed")
	main.walk_paused = true
	var paused_position: Vector2 = game.player_position
	main._advance_walk(1.0)
	if game.player_position != paused_position: return _fail("Pause failed")
	main.walk_paused = false
	main._advance_walk(1.0)
	if main.screen != "battle" or game.enemy_id != "donut": return _fail("Auto encounter failed")
	main._battle_command(3)
	main.anim_time = 0; main._finish_battle()
	main._advance_walk(3.5)
	if game.enemy_id != "cake" or game.stage_fight_count != 2: return _fail("Auto next encounter/replay protection failed")

	print("Game over routes: hp, calories, motivation OK")
	print("Automatic meandering movement, pause and replay protection OK")
	if not _test_stage_two(main,game):
		quit(1)
		return
	main.free()
	await process_frame
	quit(0)

func _test_stage_two(main: Control,game: Node) -> bool:
	var route := ["s2_donut","s2_karaage","s2_pizza","s2_burger","s2_parfait","s2_ramen","s2_feast","s2_final"]
	# Exercise the actual combat/level/rest/exit code, including both required bites.
	var plans := [[1,1,1,2,1,1,2,1],[1,1,1,2,1,1,2,3],[2,1,1,3,1,1,2,3]]
	for plan in plans:
		for trial in range(200):
			seed(trial)
			main._start_game()
			main._start_stage_two()
			for i in range(8):
				game.enemy_id = route[i]
				game.encounter_id = "stage2_%02d" % (i+1)
				main._start_battle()
				var turns := 0
				while main.screen == "battle" and not main.battle_finished and turns < 100:
					main._battle_command(plan[i])
					turns += 1
				if main.screen == "game_over":
					printerr("Stage 2 planned route failed: ",plan," seed ",trial," battle ",i," ",main.game_over_reason)
					return false
				main.anim_time = 0; main._finish_battle()
			game.player_position.x = 2425
			main._check_encounter(2400)
			if main.screen != "clear" or game.stage_fight_count != 8 or game.fight_count != game.fight_win_count+game.eat_count+game.call_count:
				printerr("Stage 2 clear/counts failed")
				return false
	print("Stage 2 planned routes: 3 strategies x 200 damage seeds cleared")
	main._start_game()
	main._start_stage_two()
	seed(42)
	for cmd in plans[0]:
		main._advance_walk(10.0)
		if main.screen != "battle": return false
		while main.screen == "battle" and not main.battle_finished:
			main._battle_command(cmd)
		if main.screen == "game_over": return false
		main.anim_time = 0; main._finish_battle()
	main._advance_walk(10.0)
	if main.screen != "clear" or game.stage_fight_count != 8: return false
	print("Automatic Stage 2 route reaches all 8 enemies and home")
	for plan in [[1,1,1,1,1,1,2,1],[3,3,3,3,3,3,2,3],[2,1,1,2,1,1,2,3]]:
		main._start_game()
		main._start_stage_two()
		seed(0)
		for i in range(8):
			game.enemy_id = route[i]
			game.encounter_id = "stage2_%02d" % (i+1)
			main._start_battle()
			var turns := 0
			while main.screen == "battle" and not main.battle_finished and turns < 100:
				main._battle_command(plan[i])
				turns += 1
			if main.screen == "game_over": break
			main.anim_time = 0; main._finish_battle()
		if main.screen != "game_over":
			printerr("Unmanaged Stage 2 strategy unexpectedly passed: ",plan)
			return false
	print("Stage 2 all-fight, all-call and over-eating strategies lose as designed")
	for y in [285,365,445]:
		main._start_stage_two()
		# A player who reaches gate 7 has necessarily cleared the preceding gates.
		for i in range(6): game.completed["stage2_%02d" % (i+1)] = true
		game.player_position = Vector2(1998,y)
		main._check_encounter(1970)
		if main.screen != "battle" or game.enemy_id != "s2_feast":
			printerr("Mandatory feast bypass at y=",y)
			return false
	main._start_stage_two()
	game.enemy_id = "s2_feast"
	game.encounter_id = "stage2_07"
	main._start_battle()
	main._battle_command(3)
	if main.battle_finished or game.call_count != 0 or game.current_hp != 136 or game.motivation != 80:
		printerr("Feast blocked call changed resources")
		return false
	main._battle_command(1)
	if main.enemy_hp != 999 or game.current_hp >= 136:
		printerr("Feast invulnerability/counter failed")
		return false
	# Exact calorie boundary, plus no completion after first bite.
	for start_cal in [499,500]:
		main._start_stage_two()
		game.enemy_id = "s2_feast"
		game.encounter_id = "stage2_07"
		game.calories = start_cal
		main._start_battle()
		main._battle_command(2)
		if main.battle_finished or game.completed.has("stage2_07") or game.calories != start_cal+550:
			printerr("Feast first bite completed too soon")
			return false
		main._battle_command(2)
		if start_cal == 499 and (not main.battle_finished or main.screen != "battle" or game.calories != 1599): return false
		if start_cal == 500 and (main.screen != "game_over" or main.game_over_reason != "calories"): return false
	# Checkpoint preserves stage 1 results and discards the failed stage 2 attempt.
	main._start_game()
	game.fight_count = 8
	game.fight_win_count = 6
	game.eat_count = 1
	game.call_count = 1
	game.completed["encounter_08"] = true
	main._start_stage_two()
	game.fight_count += 3
	game.eat_count += 2
	game.completed["stage2_01"] = true
	main._start_stage_two()
	if game.fight_count != 8 or game.eat_count != 1 or game.player_level != 4 or game.current_hp != 136 or game.calories != 900 or game.motivation != 80 or game.completed.has("stage2_01") or not game.completed.has("encounter_08"):
		printerr("Stage 2 checkpoint failed")
		return false
	print("Stage 2 mandatory gate, two bites, immunity, 499/500 boundary and retry checkpoint OK")
	return true

func _fail(message: String) -> void:
	printerr(message)
	quit(1)
