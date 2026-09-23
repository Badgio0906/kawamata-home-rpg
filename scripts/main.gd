extends Control

const W := 960.0
const H := 540.0
const WORLD_WIDTH := 2560.0
const STAGE_TWO_REST := 60
const STAGE_TWO_GATES := [
	{"id":"stage2_01","enemy":"s2_donut","x":310.0,"optional":false},
	{"id":"stage2_02","enemy":"s2_karaage","x":585.0,"optional":false},
	{"id":"stage2_03","enemy":"s2_pizza","x":865.0,"optional":false},
	{"id":"stage2_04","enemy":"s2_burger","x":1145.0,"optional":false},
	{"id":"stage2_05","enemy":"s2_parfait","x":1425.0,"optional":false},
	{"id":"stage2_06","enemy":"s2_ramen","x":1705.0,"optional":false},
	{"id":"stage2_07","enemy":"s2_feast","x":1995.0,"optional":false},
	{"id":"stage2_08","enemy":"s2_final","x":2235.0,"optional":false},
]
const GATES := [
	{"id":"encounter_01","enemy":"donut","x":310.0,"optional":false},
	{"id":"encounter_02","enemy":"cake","x":585.0,"optional":false},
	{"id":"encounter_03","enemy":"karaage","x":865.0,"optional":false},
	{"id":"encounter_04","enemy":"burger","x":1145.0,"optional":false},
	{"id":"encounter_05","enemy":"pizza","x":1425.0,"optional":false},
	{"id":"encounter_06","enemy":"parfait","x":1705.0,"optional":false},
	{"id":"encounter_07","enemy":"ramen","x":1945.0,"optional":false},
	{"id":"encounter_08","enemy":"final","x":2235.0,"optional":false},
	{"id":"encounter_09","enemy":"donut","x":730.0,"optional":true},
	{"id":"encounter_10","enemy":"burger","x":1570.0,"optional":true},
	{"id":"encounter_11","enemy":"cake","x":2090.0,"optional":true},
]

var font: Font
var art: Dictionary = {}
var town_atlas: Texture2D
var town_shapes: Dictionary = {}
var sounds: Dictionary = {}
var music: AudioStreamPlayer
var se: AudioStreamPlayer
var music_name := ""
var muted := false
var screen := "title"
var last_screen := ""
var camera_x := 0.0
var walk_paused := false
var speech_time := 0.0
var speech_cooldown := 0.0
var segment_start := 260.0
var player_facing := Vector2.DOWN
var move_time := 0.0
var enemy: Dictionary = {}
var enemy_hp := 0
var bites := 0
var battle_finished := false
var battle_text: Array[String] = []
var game_over_reason := ""
var anim_kind := ""
var anim_time := 0.0
var damage_label := ""
var flash_time := 0.0
var field_notice := ""
var field_notice_time := 0.0

func _ready() -> void:
	font = load("res://assets/fonts/DotGothic16.ttf")
	town_atlas = load("res://assets/rpg/town_atlas.png")
	town_shapes = JSON.parse_string(FileAccess.get_file_as_string("res://data/town_art.json"))
	for name in ["donut","cake","karaage","burger","pizza","parfait","ramen","final","player_front","player_back","player_side","player_front_walk_a","player_front_walk_b","player_back_walk_a","player_back_walk_b","player_side_walk_a","player_side_walk_b","player_fallen","player_seated","office","home","sweets","diner","shop","houses","tree","lamp"]:
		art[name] = load("res://assets/generated/%s.png" % name)
	art["helper"] = load("res://assets/rpg/helper_atlas.png")
	art["station"] = load("res://assets/rpg/station.png")
	art["feast"] = load("res://assets/rpg/feast.png")
	var hero: Texture2D = load("res://assets/rpg/hero_atlas.png")
	var cell := hero.get_width() / 3.0
	for row in range(3):
		for col in range(3):
			var frame := AtlasTexture.new()
			frame.atlas = hero
			frame.region = Rect2(col*cell,row*cell,cell,cell)
			frame.filter_clip = true
			var suffix: String = ["_walk_a","","_walk_b"][col]
			art["player_" + ["front","back","side"][row] + suffix] = frame
	var endings: Texture2D = load("res://assets/rpg/hero_endings.png")
	for col in range(3):
		var frame := AtlasTexture.new()
		frame.atlas = endings
		frame.region = Rect2(col*endings.get_width()/3.0,0,endings.get_width()/3.0,endings.get_height())
		frame.filter_clip = true
		art[["player_seated","player_fallen","player_happy"][col]] = frame
	for name in ["select","cancel","encounter","attack","damage","eat","phone","victory","level","gameover","clear","bgm_title","bgm_field","bgm_battle","bgm_ending"]:
		sounds[name] = load("res://assets/audio/%s.wav" % name)
	music = AudioStreamPlayer.new()
	music.volume_db = -13.0
	add_child(music)
	music.finished.connect(_on_music_finished)
	se = AudioStreamPlayer.new()
	se.volume_db = -3.0
	add_child(se)
	set_process(true)
	set_process_input(true)
	_start_music("title")

func _on_music_finished() -> void:
	if music_name != "" and not muted:
		music.play()

func _start_music(name: String) -> void:
	if music_name == name:
		return
	music_name = name
	music.stop()
	music.stream = sounds["bgm_" + name]
	if not muted:
		music.play()

func _sound(name: String) -> void:
	if muted:
		return
	se.stop()
	se.stream = sounds[name]
	se.play()

func _process(delta: float) -> void:
	if screen != last_screen:
		last_screen = screen
		match screen:
			"title": _start_music("title")
			"field": _start_music("field")
			"battle": _start_music("battle")
			_: _start_music("ending")
	if anim_time > 0:
		anim_time = maxf(0, anim_time - delta)
	if flash_time > 0:
		flash_time = maxf(0, flash_time - delta)
	if field_notice_time > 0:
		field_notice_time = maxf(0, field_notice_time - delta)
	if screen == "field":
		_advance_walk(delta)
		camera_x = clampf(Game.player_position.x - 470.0, 0.0, WORLD_WIDTH - W)
	queue_redraw()

func _gates() -> Array:
	var route: Array = STAGE_TWO_GATES if Game.stage == 2 else GATES
	return route.filter(func(gate: Dictionary) -> bool: return not gate.optional)

func _advance_walk(delta: float) -> void:
	if walk_paused or screen != "field": return
	var target_x := 2440.0
	for gate in _gates():
		if not Game.completed.has(gate.id):
			target_x = float(gate.x)
			break
	var old_x := Game.player_position.x
	Game.player_position.x = minf(target_x,old_x + 88.0*delta)
	var progress := clampf((Game.player_position.x-segment_start)/maxf(1,target_x-segment_start),0,1)
	Game.player_position.y = 365.0 + sin(progress*TAU)*24.0
	player_facing = Vector2.RIGHT
	move_time += delta
	speech_cooldown -= delta
	speech_time = maxf(0,speech_time-delta)
	if speech_cooldown <= 0:
		speech_time = 2.6
		speech_cooldown = 6.5
	_check_encounter(old_x)

func _check_encounter(old_x: float) -> void:
	for gate in _gates():
		if Game.completed.has(gate.id):
			continue
		if gate.optional and Game.player_position.y > 332:
			continue
		if absf(Game.player_position.x - gate.x) < 17.0 or (old_x < gate.x and Game.player_position.x >= gate.x):
			Game.encounter_id = gate.id
			Game.enemy_id = gate.enemy
			_start_battle()
			return
	var last_gate := "stage2_08" if Game.stage == 2 else "encounter_08"
	if Game.player_position.x > 2420.0 and Game.completed.has(last_gate):
		screen = "clear" if Game.stage == 2 else "station"
		_sound("clear")

func _start_battle() -> void:
	enemy = Game.enemies[Game.enemy_id]
	enemy_hp = int(enemy.hp)
	bites = 0
	battle_finished = false
	battle_text = ["%sが誘惑してきた！" % enemy.name]
	if enemy.get("eat_required",1) > 1:
		battle_text = ["二段のごちそうが立ちはだかった！", "この大きさ……一度では食べきれない。"]
	Game.fight_count += 1
	Game.stage_fight_count += 1
	anim_kind = ""
	anim_time = 0
	screen = "battle"
	_sound("encounter")

func _battle_command(cmd: int) -> void:
	if battle_finished:
		if cmd == 0:
			_finish_battle()
		return
	if cmd == 1:
		var damage := maxi(1, roundi(Game.attack * Game.modifier() - int(enemy.defense) + randi_range(-2,2)))
		if enemy.get("invulnerable",false): damage = 0
		enemy_hp = maxi(0, enemy_hp - damage)
		battle_text = ["河俣さんは誘惑に耐えた！", "%sに%dのダメージ！" % [enemy.name,damage]]
		if enemy.get("invulnerable",false):
			battle_text = ["ごちそうの壁はびくともしない！", "この敵は食べるを2回でしか倒せない。"]
		anim_kind = "fight"
		anim_time = 0.45
		_sound("attack")
		if enemy_hp <= 0:
			_win_fight()
		else:
			var incoming := maxi(1, roundi(int(enemy.attack) - Game.defense * Game.modifier() + randi_range(-2,2)))
			Game.current_hp = maxi(0, Game.current_hp - incoming)
			battle_text.append("甘い香りが襲う！ HP -%d" % incoming)
			if Game.current_hp <= 0:
				_game_over("hp")
				return
	elif cmd == 2:
		bites += 1
		Game.current_hp = mini(Game.max_hp, Game.current_hp + int(enemy.eat_heal))
		Game.calories += int(enemy.eat_calories)
		Game.motivation = mini(100, Game.motivation + int(enemy.eat_motivation))
		battle_text = ["河俣さんは食べてしまった！", "おいしい！ HPとやる気が回復した！", "カロリー +%d kcal" % int(enemy.eat_calories)]
		anim_kind = "eat"
		anim_time = 0.7
		_sound("eat")
		if bites >= int(enemy.get("eat_required",1)):
			Game.eat_count += 1
			_complete_encounter()
		else:
			enemy_hp = roundi(float(enemy.hp) * (1.0-float(bites)/int(enemy.eat_required)))
			battle_text = ["一段目を食べた！ まだもう一段ある！", "カロリー +550 / HP +22 / やる気 +12", "あと1回、食べると +550 kcal。"]
	elif cmd == 3:
		if enemy.get("cannot_call",false):
			battle_text = ["助けを呼んだが、大きすぎて運べない！", "HP・カロリー・やる気の変化はありません。", "この敵は食べるを2回で突破しよう。"]
			_sound("phone")
			return
		Game.call_count += 1
		Game.motivation = maxi(0, Game.motivation - int(enemy.motivation_cost))
		battle_text = ["助けを呼んだ！", "誰かが誘惑を持っていってくれた！", "やる気 -%d" % int(enemy.motivation_cost)]
		anim_kind = "call"
		anim_time = 2.4
		_sound("phone")
		_complete_encounter()
	var fail := Game.failure()
	if fail != "":
		_game_over(fail)
	queue_redraw()

func _win_fight() -> void:
	Game.fight_win_count += 1
	Game.calories = maxi(0, Game.calories + int(enemy.fight_calories))
	Game.motivation = maxi(0, Game.motivation - int(enemy.motivation_cost))
	var levels := Game.gain_exp(int(enemy.exp))
	battle_text.append("誘惑に打ち勝った！ EXP +%d" % int(enemy.exp))
	battle_text.append("カロリー %d / やる気 -%d" % [int(enemy.fight_calories),int(enemy.motivation_cost)])
	for level in levels:
		battle_text.append("河俣さんはLv.%dになった！" % level)
	if levels.size() > 0:
		flash_time = 0.4
		_sound("level")
	else:
		_sound("victory")
	_complete_encounter()

func _complete_encounter() -> void:
	enemy_hp = 0
	Game.completed[Game.encounter_id] = true
	battle_finished = true

func _finish_battle() -> void:
	if anim_kind == "call" and anim_time > 0: return
	if Game.failure() != "":
		_game_over(Game.failure())
		return
	screen = "field"
	Game.player_position.x += 26.0
	segment_start = Game.player_position.x
	if Game.encounter_id in ["encounter_04","encounter_06","encounter_07"]:
		var before := Game.current_hp
		var heal := 45 if Game.encounter_id == "encounter_04" else 100 if Game.encounter_id == "encounter_06" else 50
		Game.current_hp = mini(Game.max_hp, Game.current_hp + heal)
		var morale := 0
		if Game.player_level >= 2 and Game.encounter_id != "encounter_07":
			morale = mini(8,100-Game.motivation)
			Game.motivation += morale
		field_notice = "ベンチで一休み！ HP +%d やる気 +%d" % [Game.current_hp - before,morale]
		field_notice_time = 3.5
	if Game.encounter_id == "stage2_03":
		var before := Game.current_hp
		Game.current_hp = mini(Game.max_hp,Game.current_hp + STAGE_TWO_REST)
		field_notice = "最後のベンチで休憩！ HP +%d" % (Game.current_hp-before)
		field_notice_time = 5.0
	_sound("select")

func _game_over(reason: String) -> void:
	game_over_reason = reason
	screen = "game_over"
	_sound("gameover")

func _draw() -> void:
	match screen:
		"title": _draw_title()
		"field": _draw_field()
		"battle": _draw_battle()
		"game_over": _draw_end(false)
		"clear": _draw_end(true)
		"station","briefing": _draw_briefing()
	_draw_mute()
	if flash_time > 0:
		draw_rect(Rect2(0,0,W,H),Color(1,1,0.9,flash_time * 0.7))

func _rect(x: float,y: float,w: float,h: float,color: Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func _round(x: float,y: float,w: float,h: float,color: Color, radius: int = 12) -> void:
	# Stepped corners and a double border belong to the same pixel grid as the art.
	if w <= 0 or h <= 0: return
	var edge := 3.0 if radius > 5 else 1.0
	_rect(x+edge,y,w-edge*2,h,Color("#304e50"))
	_rect(x,y+edge,w,h-edge*2,Color("#304e50"))
	_rect(x+edge,y+edge,w-edge*2,h-edge*2,color)
	if radius > 5:
		_rect(x+6,y+5,w-12,2,color.lightened(0.3))
		_rect(x+5,y+6,2,h-12,color.lightened(0.3))
		_rect(x+6,y+h-7,w-12,2,color.darkened(0.18))

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s

func _text(t: String,x: float,y: float,size: int=22,color: Color=Color.WHITE,width: float=-1) -> void:
	draw_string(font,Vector2(x,y),t,HORIZONTAL_ALIGNMENT_LEFT,width,size,color)

func _center(t: String,x: float,y: float,width: float,size: int=22,color: Color=Color.WHITE) -> void:
	draw_string(font,Vector2(x,y),t,HORIZONTAL_ALIGNMENT_CENTER,width,size,color)

func _sprite(name: String,x: float,y: float,w: float,h: float,flip: bool=false) -> void:
	if town_shapes.has(name):
		var shape: Dictionary = town_shapes[name]
		var b: Array = shape.bounds
		var atlas: Texture2D = art[shape.texture] if shape.has("texture") else town_atlas
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for pair in shape.outline:
			var local_x: float = (float(pair[0])-b[0])/b[2]*w
			points.append(Vector2(x+w-local_x if flip else x+local_x,y+(float(pair[1])-b[1])/b[3]*h))
			uvs.append(Vector2(float(pair[0])/atlas.get_width(),float(pair[1])/atlas.get_height()))
		draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,atlas)
		return
	var tex: Texture2D = art[name]
	if flip:
		draw_set_transform(Vector2(x+w,y),0.0,Vector2(-1,1))
		draw_texture_rect(tex,Rect2(0,0,w,h),false)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect(tex,Rect2(x,y,w,h),false)

func _button(t: String,box: Rect2,active: bool=true,size: int=24) -> void:
	_round(box.position.x+3,box.position.y+5,box.size.x,box.size.y,Color("#293148"),10)
	_round(box.position.x,box.position.y,box.size.x,box.size.y,Color("#f4edce") if active else Color("#87968b"),10)
	_center(t,box.position.x,box.position.y+box.size.y/2+size*0.37,box.size.x,size,Color("#3d3947") if active else Color.WHITE)

func _draw_title() -> void:
	_draw_town(410.0)
	_rect(0,0,W,H,Color("#304e50",0.16))
	_round(164,26,632,180,Color("#fff4d1"),12)
	_center("河俣さんの",178,93,604,42,Color("#405356"))
	_center("おうち帰れるかな",178,157,604,50,Color("#bd666b"))
	_round(242,218,476,40,Color("#385b58"),8)
	_center("誘惑に負けず、おうちまで帰ろう！",250,246,460,20,Color("#fff1c6"))
	_sprite("player_front",408,278,144,144)
	_sprite("donut",303,327,64,64)
	_sprite("cake",578,327,64,64)
	_button("1  職場から出発",Rect2(175,435,292,72),true,25)
	_button("2  駅から出発・上級",Rect2(489,435,300,72),true,23)

func _draw_briefing() -> void:
	_draw_town(1550)
	_rect(0,0,W,H,Color("#203552",0.55))
	_round(42,26,814,490,Color("#fff1d8"),12)
	_center("阪神尼崎駅に到着！" if screen == "station" else "STAGE 2  駅からおうちへ",62,76,774,32,Color("#5c4964"))
	_sprite("station",67,105,280,170)
	_sprite("player_front",165,306,100,100)
	_center("阪神尼崎駅",72,297,267,22,Color("#435957"))
	_text("夜の帰り道は、計画的に。",368,122,25,Color("#624b62"))
	_text("Lv.4 / HP136 / 900 kcal / やる気80",368,163,20,Color("#425957"))
	_text("駅で準備して、この数値からスタート。",368,191,19,Color("#425957"))
	_text("・食べ物へ、つい足が向いてしまう。",368,231,20,Color("#425957"))
	_text("・移動は自動。戦闘で作戦を選ぼう。",368,268,20,Color("#425957"))
	_text("・手強い誘惑が待つ、上級コース。",368,305,20,Color("#425957"))
	_round(365,325,453,76,Color("#754c5f"),8)
	_text("戦う・食べる・誰かを呼ぶ",383,355,23,Color("#ffe3a0"))
	_text("今日こそ、無事に帰りたい！",383,385,22)
	_text("駅を出たら、おうちまでもうひと頑張り。",123,430,22,Color("#5c4964"))
	_button("2ステージ目へ",Rect2(187,440,330,70),true,25)
	_button("タイトルへ",Rect2(545,440,238,70),true,23)

func _draw_town(offset: float) -> void:
	_rect(0,0,W,H,Color("#8bb479"))
	# Deterministic 32px grass and paving tiles scroll together with the world.
	for row in range(17):
		for col in range(int(offset/32.0),int(offset/32.0)+32):
			var tx := col*32.0-offset
			var ty := row*32.0
			var pattern := (col*17+row*31)%7
			_rect(tx+4+pattern,ty+13,3,3,Color("#77a26c"))
			_rect(tx+17,ty+7+pattern,6,2,Color("#a9c58a"))
	_rect(0,269,W,183,Color("#677c69"))
	_rect(0,276,W,169,Color("#d8c99a"))
	_rect(0,278,W,4,Color("#f7e6b5"))
	_rect(0,440,W,5,Color("#baa97d"))
	for row in range(5):
		for col in range(int(offset/48.0)-1,int(offset/48.0)+22):
			var tx := col*48.0-offset+float(row%2)*24.0
			_rect(tx,283+row*31,46,29,Color("#ded1a4") if (col+row)%3 else Color("#d1c393"))
			_rect(tx+3,285+row*31,40,2,Color("#eddfb4"))
	for i in range(22):
		var tx := i*128.0-offset
		if tx < -128 or tx > W: continue
		_sprite("tree",tx,-70,128,158)
		_sprite("tree",tx+40,463,114,140)
		_rect(tx+18,461,96,4,Color("#f0e6c2"))
		for post in range(4):
			_rect(tx+20+post*27,451,5,24,Color("#f0e6c2"))
	for i in range(10):
		var bx := i*255.0+14.0-offset
		if bx < -250 or bx > W: continue
		var kind: String = ["office","sweets","sweets","diner","shop","diner","shop","diner","houses","home"][i]
		if (Game.stage == 1 and i == 9) or (Game.stage == 2 and i == 0): kind = "station"
		_sprite(kind,bx-22 if kind == "station" else bx,125 if kind == "station" else 77,245 if kind == "station" else 195,142 if kind == "station" else 195)
		_sprite("tree",bx+190,156,66,96)
		var shop_name: String = ["職場","洋菓子店","ドーナツ","揚げもの","バーガー","ピザ","スーパー","ラーメン","住宅街","おうち"][i]
		if kind == "station": shop_name = "阪神尼崎駅"
		elif Game.stage == 2:
			shop_name = ["駅前","夜のドーナツ","唐揚げ弁当","ピザ屋","バーガー","パフェ店","ラーメン","大盛り横丁","住宅街","おうち"][i]
		_round(bx+35,248,128,27,Color("#fff0ca"),6)
		_center(shop_name,bx+35,268,128,16,Color("#425957"))
	for bench_x in ([905.0] if Game.stage == 2 else [1180.0,1740.0,2000.0]):
		var bx: float = bench_x-offset
		if bx > -100 and bx < W:
			_sprite("bench",bx,231,87,49)
	if Game.stage == 2:
		_rect(0,0,W,H,Color("#252650",0.22))
		for i in range(10):
			var lx := i*255.0+205-offset
			if lx < -40 or lx > W+40: continue
			_oval(Vector2(lx,281),39,10,Color("#ffe3a0",0.20))
			_sprite("lamp",lx-16,215,32,65)

func _draw_field() -> void:
	_draw_town(camera_x)
	for gate in _gates():
		if Game.completed.has(gate.id): continue
		var x: float = gate.x-camera_x
		if x < -50 or x > W+50: continue
		var gy := 319.0 if gate.optional else 361.0
		_rect(x-18,gy+28,36,4,Color("#9c946d"))
		var enemy_art: String = Game.enemies[gate.enemy].get("art",gate.enemy)
		var sz := 76.0 if gate.enemy == "s2_feast" else 48.0
		_sprite(enemy_art,x-sz/2,gy+32-sz,sz,sz)
		if gate.enemy == "s2_feast":
			_round(x-95,gy-70,190,30,Color("#754c5f"),6)
			_center("必須  食べる×2",x-95,gy-48,190,17)
		if gate.optional:
			_text("寄り道",x-23,gy+57,14,Color("#4b6859"))
	var moving := not walk_paused
	var direction_name := "side" if absf(player_facing.x) > absf(player_facing.y) else ("front" if player_facing.y > 0 else "back")
	var walk := "player_" + direction_name
	if moving:
		walk += "_walk_a" if int(move_time*8)%2 == 0 else "_walk_b"
	_oval(Vector2(Game.player_position.x-camera_x,Game.player_position.y-3),17,5,Color("#687b60",0.4))
	_sprite(walk,Game.player_position.x-camera_x-34,Game.player_position.y-68,68,68,player_facing.x < 0 and direction_name == "side")
	_draw_hud()
	_button("歩き出す" if walk_paused else "ひと休み",Rect2(30,440,194,72),true,22)
	if speech_time > 0: _draw_walk_speech()

	if field_notice_time > 0:
		_round(299,145,555,42,Color("#252d49"),8)
		_text(field_notice,312,173,20)

func _draw_hud() -> void:
	_round(13,12,662,81,Color("#385b58"),12)
	_text("Lv.%d" % Game.player_level,25,44,24,Color("#ffe5a9"))
	_draw_meter("HP",Game.current_hp,Game.max_hp,112,22,Color("#7dd8ad"),Game.current_hp <= Game.max_hp*0.25)
	_draw_meter("カロリー",Game.calories,1600,300,22,Color("#f4bc75"),Game.calories >= 1300)
	_draw_meter("やる気",Game.motivation,100,498,22,Color("#9ac8f2"),Game.motivation <= 25)
	_round(692,12,174,57,Color("#fff0ca"),8)
	_text("STAGE %d" % Game.stage,705,33,17,Color("#405958"))
	_text("戦闘 %d/%s" % [Game.stage_fight_count,"8"],705,56,17,Color("#405958"))

func _draw_meter(label: String,value: int,max_value: int,x: float,y: float,c: Color,warn: bool) -> void:
	_text(("! " if warn else "")+label,x,y+19,17,Color("#ff8388") if warn else Color.WHITE)
	_round(x,y+27,158,12,Color("#454864"),5)
	_round(x,y+27,158.0*clampf(float(value)/max_value,0,1),12,c,5)
	_text("%d / %d" % [value,max_value],x,y+60,17,Color("#ff8588") if warn else Color("#e9e8df"))

func _draw_walk_speech() -> void:
	var px := Game.player_position.x-camera_x
	var py := Game.player_position.y-77
	var bx := clampf(px-151,14,W-316)
	_round(bx,py-74,302,64,Color("#fff5df"),8)
	draw_colored_polygon(PackedVector2Array([Vector2(px-8,py-12),Vector2(px+9,py-12),Vector2(px,py+2)]),Color("#fff5df"))
	_center("勝手に",bx+8,py-47,286,20,Color("#655064"))
	_center("吸い寄せられてしまう！",bx+8,py-21,286,20,Color("#655064"))

func _draw_battle() -> void:
	for band in range(8):
		_rect(0,band*24,W,24,Color("#83b8b4").lerp(Color("#f5d3a0"),float(band)/8.0))
	_rect(0,187,W,353,Color("#a6be82"))
	for i in range(11):
		_sprite("tree",i*96-20,65,117,145)
	_sprite("sweets",30,93,111,118)
	_sprite("home",490,91,108,120)
	_rect(0,212,W,110,Color("#c4d296"))
	for i in range(39):
		_rect((i*83)%960,220+(i*37)%98,8,3,Color("#9bb77b"))
		_rect((i*83+11)%960,223+(i*37)%98,3,4,Color("#9bb77b"))
	if Game.stage == 2: _rect(0,0,W,326,Color("#252650",0.23))
	_oval(Vector2(710,282),118,21,Color("#76966a"))
	_oval(Vector2(710,279),111,17,Color("#e2d19d"))
	_oval(Vector2(205,310),110,24,Color("#76966a"))
	_oval(Vector2(205,306),103,19,Color("#e2d19d"))
	var long_name: bool = str(enemy.name).length() > 12
	_round(640,62,257,96,Color("#fff0d9"),10)
	if long_name:
		_text(str(enemy.name).substr(0,10),653,86,18,Color("#514354"))
		_text(str(enemy.name).substr(10),653,108,18,Color("#514354"))
	else:
		_text(enemy.name,655,103,20,Color("#514354"),230)
	_draw_bar(660,119,216,float(enemy_hp)/float(enemy.hp),Color("#e47d7c"))
	_text("残り %d 段 / 食べる2回" % maxi(0,2-bites) if enemy.get("invulnerable",false) else "HP %d / %d" % [enemy_hp,int(enemy.hp)],657,146,14,Color("#544a5c"))
	_round(22,18,594,72,Color("#385b58"),8)
	if enemy.get("invulnerable",false):
		_text("そびえ立つ、二段のごちそう！",36,46,20,Color("#ffe3a0"))
		_text("食事1回：+550 kcal / HP +22 / やる気 +12",36,75,19)
	else:
		_text("勝利：%d kcal / やる気 -%d / EXP +%d" % [int(enemy.fight_calories),int(enemy.motivation_cost),int(enemy.exp)],36,46,19)
		_text("食事：+%d kcal / HP +%d / やる気 +%d" % [int(enemy.eat_calories),int(enemy.eat_heal),int(enemy.eat_motivation)],36,75,19,Color("#ffe3a0"))
	var enemy_x := 645.0
	var enemy_y := 153.0
	var scale := 1.0
	if enemy.get("eat_required",1) > 1 and bites == 1: scale = 0.72
	if anim_kind == "eat" and anim_time > 0:
		scale = lerpf(0.72,1.0,anim_time/0.7) if not battle_finished else maxf(0.05,anim_time/0.7)
	if anim_kind == "call" and anim_time > 0:
		_draw_helper_call()
	elif not (battle_finished and anim_time <= 0) and not (anim_kind == "fight" and anim_time > 0 and int(anim_time*18)%2 == 0):
		_sprite(enemy.get("art",Game.enemy_id),enemy_x+65*(1-scale),enemy_y+130*(1-scale),130*scale,130*scale)
	var px := 130.0 + (18.0 if anim_kind == "fight" and anim_time > 0 else 0.0)
	_sprite("player_back",px,160,152,152)
	if anim_kind == "eat" and anim_time > 0:
		for i in range(6):
			var sx := px-18+i*39
			var sy := 176.0+18*(i%2)
			draw_line(Vector2(sx-8,sy),Vector2(sx+8,sy),Color("#ffe482"),3)
			draw_line(Vector2(sx,sy-8),Vector2(sx,sy+8),Color("#ffe482"),3)
	_round(32,326,896,202,Color("#385b58"),13)
	_round(42,336,876,182,Color("#fff4d6"),10)
	_text("河俣さん  Lv.%d" % Game.player_level,57,368,23,Color("#544658"))
	_text("HP %d/%d   カロリー %d/1600   やる気 %d/100" % [Game.current_hp,Game.max_hp,Game.calories,Game.motivation],303,368,21,Color("#594c57"))
	for i in range(mini(3,battle_text.size())):
		_text(battle_text[maxi(0,battle_text.size()-3)+i],59,394+i*25,18,Color("#594c57"),830)
	if battle_finished:
		_button("お届け中…" if anim_kind == "call" and anim_time > 0 else "つづける",Rect2(330,449,300,70),not (anim_kind == "call" and anim_time > 0),22)
	else:
		_button("1  戦う",Rect2(58,449,260,70),true,21)
		_button("2  食べる",Rect2(350,449,260,70),true,21)
		_button("3  誰かを呼ぶ",Rect2(642,449,260,70),true,21)

func _draw_helper_call() -> void:
	# The helper walks in, collects the food on a tray, then carries it away.
	var elapsed := 2.4-anim_time
	var collecting := clampf((elapsed-0.7)/0.5,0,1)
	var leaving := elapsed >= 1.35
	var helper_x := lerpf(975,756,clampf(elapsed/0.7,0,1))
	if leaving: helper_x = lerpf(756,1010,clampf((elapsed-1.35)/1.05,0,1))
	var bob := sin(elapsed*22)*2.0 if elapsed < 0.7 or leaving else 0.0
	_sprite("helper_walk" if elapsed < 0.7 else "helper_carry",helper_x,142+bob,80,160,leaving)
	var food_size := lerpf(130,49,collecting)
	var food_center := Vector2(710,218).lerp(Vector2(helper_x+11,206+bob),collecting)
	if leaving: food_center = Vector2(helper_x+69,206+bob)
	_sprite(enemy.get("art",Game.enemy_id),food_center.x-food_size/2,food_center.y-food_size/2,food_size,food_size)
	_round(305,152,288,54,Color("#fff1d8"),8)
	_center("あとは任せて！" if elapsed > 0.7 else "助っ人に電話中…",316,187,266,22,Color("#5c4964"))
	if elapsed < 0.7:
		_round(269,204,27,44,Color("#354c57"),4)
		_rect(274,210,17,27,Color("#acd7c5"))
		_rect(281,240,4,3,Color("#fff1d8"))

func _draw_bar(x: float,y: float,w: float,p: float,c: Color) -> void:
	_round(x,y,w,10,Color("#9994a2"),5)
	_round(x,y,w*clampf(p,0,1),10,c,5)

func _oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := float(i)/32.0*TAU
		points.append(center+Vector2(roundf(cos(angle)*rx),roundf(sin(angle)*ry)))
	draw_colored_polygon(points,color)

func _draw_end(won: bool) -> void:
	_draw_town(1500)
	_rect(0,0,W,H,Color("#304e50",0.45))
	if won:
		_rect(0,0,476,276,Color("#e6d7ad"))
		_rect(0,276,476,264,Color("#bf936c"))
		for row in range(9):
			for col in range(7):
				_rect(col*80-(row%2)*40,280+row*31,78,29,Color("#d2ad7e"))
		_rect(0,268,476,8,Color("#947958"))
		_round(33,308,392,104,Color("#96b2a0"),9)
		_round(37,189,368,157,Color("#567b77"),13)
		_round(66,170,312,118,Color("#8caf94"),13)
		_rect(88,188,93,73,Color("#a5c2a5"))
		_rect(267,188,93,73,Color("#a5c2a5"))
		_rect(21,90,125,115,Color("#524866"))
		_rect(29,98,109,99,Color("#393f66"))
		_rect(81,98,5,99,Color("#e8ccaa"))
		_sprite("player_happy",159,179,208,208)
		_round(140,348,270,24,Color("#674d5a"),8)
		_round(477,35,445,375,Color("#fff1d8"),15)
		_center("無事におうちへ帰れた！",492,84,414,29,Color("#6c4b61"))
		_text("最終Level      %d" % Game.player_level,530,130,21,Color("#4f4556"))
		_text("残りHP          %d / %d" % [Game.current_hp,Game.max_hp],530,166,21,Color("#4f4556"))
		_text("カロリー       %d kcal" % Game.calories,530,202,21,Color("#4f4556"))
		_text("やる気          %d / 100" % Game.motivation,530,238,21,Color("#4f4556"))
		_text("戦って勝利    %d 回" % Game.fight_win_count,530,274,21,Color("#4f4556"))
		_text("食べた          %d 回" % Game.eat_count,530,310,21,Color("#4f4556"))
		_text("誰かを呼んだ  %d 回" % Game.call_count,530,346,21,Color("#4f4556"))
		_text("総戦闘回数    %d 回" % Game.fight_count,530,382,21,Color("#4f4556"))
	else:
		if game_over_reason == "hp":
			_sprite("player_fallen",54,261,235,235)
		else:
			_sprite("player_seated",59,259,215,215)
		if game_over_reason == "calories":
			for i in range(5): _sprite(["donut","cake","burger","pizza","parfait"][i],230+i*90,321,77,77)
		elif game_over_reason == "motivation":
			_text("……",237,310,42,Color("#cec7d7"))
		_round(325,80,565,280,Color("#fff1db"),16)
		if game_over_reason == "hp":
			_center("力尽きてしまった",345,153,525,34,Color("#6c4a62"))
		elif game_over_reason == "calories":
			_center("食べ過ぎてしまった。",345,143,525,30,Color("#6c4a62"))
			_center("自暴自棄になりゲームオーバー",345,188,525,22,Color("#6c4a62"))
		else:
			_center("食べるのを我慢しすぎてやる気ゼロ。",342,143,531,24,Color("#6c4a62"))
			_center("もう帰る気にもなれない",345,188,525,24,Color("#6c4a62"))
		_center("戦闘 %d 回 / Lv.%d" % [Game.fight_count,Game.player_level],345,268,525,21,Color("#6c4a62"))
	_button("もう一度遊ぶ" if won else ("2ステージ目を再挑戦" if Game.stage == 2 else "もう一度"),Rect2(335,432,270,72),true,21)
	_button("タイトルへ",Rect2(631,432,270,72),true,24)

func _draw_mute() -> void:
	_round(877,9,72,70,Color("#f9dfaa"),9)
	_center("音OFF" if muted else "音ON",882,51,62,16,Color("#493d4d"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if screen == "battle":
			if event.keycode == KEY_1: _battle_command(1)
			elif event.keycode == KEY_2: _battle_command(2)
			elif event.keycode == KEY_3: _battle_command(3)
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE: _battle_command(0)
		elif screen == "title":
			if event.keycode in [KEY_ENTER,KEY_SPACE,KEY_1]: _start_game()
			elif event.keycode == KEY_2:
				Game.reset()
				screen = "briefing"
		elif screen in ["station","briefing"] and event.keycode in [KEY_ENTER,KEY_SPACE]:
			_start_stage_two()
		elif screen == "field" and event.keycode in [KEY_SPACE,KEY_P]:
			walk_paused = not walk_paused
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pointer_down(event.position)
	if event is InputEventScreenTouch and event.pressed:
		_pointer_down(event.position)

func _pointer_down(pos: Vector2) -> void:
	if Rect2(877,9,72,70).has_point(pos):
		muted = not muted
		if muted: music.stop()
		else: music.play()
		queue_redraw()
		return
	match screen:
		"title":
			if Rect2(175,435,292,72).has_point(pos): _start_game()
			elif Rect2(489,435,300,72).has_point(pos):
				Game.reset()
				screen = "briefing"
		"station","briefing":
			if Rect2(187,440,330,70).has_point(pos): _start_stage_two()
			elif Rect2(545,440,238,70).has_point(pos): screen = "title"
		"field":
			if Rect2(30,440,194,72).has_point(pos): walk_paused = not walk_paused
		"battle":
			if battle_finished:
				if Rect2(330,449,300,70).has_point(pos): _battle_command(0)
			else:
				if Rect2(58,449,260,70).has_point(pos): _battle_command(1)
				elif Rect2(350,449,260,70).has_point(pos): _battle_command(2)
				elif Rect2(642,449,260,70).has_point(pos): _battle_command(3)
		"game_over","clear":
			if Rect2(335,432,270,72).has_point(pos):
				if screen == "game_over" and Game.stage == 2: _start_stage_two()
				else: _start_game()
			elif Rect2(631,432,270,72).has_point(pos): screen = "title"; _sound("cancel")

func _start_game() -> void:
	Game.reset()
	camera_x = 0
	screen = "field"
	player_facing = Vector2.RIGHT
	walk_paused = false
	segment_start = Game.player_position.x
	speech_cooldown = 0
	speech_time = 0
	field_notice_time = 0
	_sound("select")

func _start_stage_two() -> void:
	Game.start_stage_two()
	screen = "field"
	camera_x = 0.0
	player_facing = Vector2.RIGHT
	walk_paused = false
	segment_start = Game.player_position.x
	speech_cooldown = 0
	speech_time = 0
	field_notice_time = 0
	_sound("select")
