extends SceneTree

const ROUTE := ["donut","cake","karaage","burger","pizza","parfait","ramen","final"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game: Node = root.get_node("Game")
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
				main._finish_battle()
			checkpoints.append([ROUTE[i],game.current_hp,game.max_hp,game.player_level,game.motivation])
		if main.screen == "field":
			game.player_position.x = 2425
			main._check_encounter(2400)
		results.append({"plan":plan,"screen":main.screen,"level":game.player_level,"hp":game.current_hp,"calories":game.calories,"motivation":game.motivation,"battles":game.fight_count,"checkpoints":checkpoints})
	print(JSON.stringify(results))
	if results[0].screen != "clear" or results[1].screen != "clear" or results[2].screen != "clear" or results[3].screen != "game_over" or results[4].screen != "game_over":
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
	game.player_position = Vector2(710,300)
	main._nudge(Vector2.RIGHT)
	if main.screen != "battle" or game.encounter_id != "encounter_09":
		printerr("Optional encounter failed")
		quit(1)
		return
	main._battle_command(3)
	main._finish_battle()
	game.player_position = Vector2(710,300)
	main._nudge(Vector2.RIGHT)
	if main.screen != "field" or not game.completed.has("encounter_09"):
		printerr("Encounter replay protection failed")
		quit(1)
		return
	print("Game over routes: hp, calories, motivation OK")
	print("Optional encounter and replay protection OK")
	quit(0)
