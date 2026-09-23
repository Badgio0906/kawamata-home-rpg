extends Control

const W := 960.0
const H := 540.0
const WORLD_WIDTH := 2560.0
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
var sounds: Dictionary = {}
var music: AudioStreamPlayer
var se: AudioStreamPlayer
var music_name := ""
var muted := false
var screen := "title"
var last_screen := ""
var camera_x := 0.0
var touch_direction := Vector2.ZERO
var mouse_down := false
var player_facing := Vector2.DOWN
var move_time := 0.0
var enemy: Dictionary = {}
var enemy_hp := 0
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
	font = load("res://assets/fonts/NotoSansJP.ttf")
	for name in ["donut","cake","karaage","burger","pizza","parfait","ramen","final","player_front","player_back","player_side","player_front_walk_a","player_front_walk_b","player_back_walk_a","player_back_walk_b","player_side_walk_a","player_side_walk_b","player_fallen","player_seated","office","home","sweets","diner","shop","houses","tree","lamp"]:
		art[name] = load("res://assets/generated/%s.png" % name)
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
		var direction := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): direction.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): direction.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): direction.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): direction.y += 1
		if touch_direction != Vector2.ZERO:
			direction = touch_direction
		if direction != Vector2.ZERO:
			var old_x := Game.player_position.x
			player_facing = direction
			Game.player_position += direction.normalized() * 155.0 * delta
			Game.player_position.x = clampf(Game.player_position.x, 70.0, WORLD_WIDTH - 80.0)
			Game.player_position.y = clampf(Game.player_position.y, 285.0, 445.0)
			move_time += delta
			_check_encounter(old_x)
		camera_x = clampf(Game.player_position.x - 470.0, 0.0, WORLD_WIDTH - W)
	queue_redraw()

func _check_encounter(old_x: float) -> void:
	for gate in GATES:
		if Game.completed.has(gate.id):
			continue
		if gate.optional and Game.player_position.y > 332:
			continue
		if absf(Game.player_position.x - gate.x) < 17.0 or (old_x < gate.x and Game.player_position.x >= gate.x):
			Game.encounter_id = gate.id
			Game.enemy_id = gate.enemy
			_start_battle()
			return
	if Game.player_position.x > 2420.0 and Game.completed.has("encounter_08"):
		screen = "clear"
		_sound("clear")

func _start_battle() -> void:
	enemy = Game.enemies[Game.enemy_id]
	enemy_hp = int(enemy.hp)
	battle_finished = false
	battle_text = ["%sが誘惑してきた！" % enemy.name]
	Game.fight_count += 1
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
		enemy_hp = maxi(0, enemy_hp - damage)
		battle_text = ["河俣さんは誘惑に耐えた！", "%sに%dのダメージ！" % [enemy.name,damage]]
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
		Game.eat_count += 1
		Game.current_hp = mini(Game.max_hp, Game.current_hp + int(enemy.eat_heal))
		Game.calories += int(enemy.eat_calories)
		Game.motivation = mini(100, Game.motivation + int(enemy.eat_motivation))
		battle_text = ["河俣さんは食べてしまった！", "おいしい！ HPとやる気が回復した！", "カロリー +%d kcal" % int(enemy.eat_calories)]
		anim_kind = "eat"
		anim_time = 0.7
		_sound("eat")
		_complete_encounter()
	elif cmd == 3:
		Game.call_count += 1
		Game.motivation = maxi(0, Game.motivation - int(enemy.motivation_cost))
		battle_text = ["助けを呼んだ！", "誰かが誘惑を持っていってくれた！", "やる気 -%d" % int(enemy.motivation_cost)]
		anim_kind = "call"
		anim_time = 0.7
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
	Game.completed[Game.encounter_id] = true
	battle_finished = true

func _finish_battle() -> void:
	if Game.failure() != "":
		_game_over(Game.failure())
		return
	screen = "field"
	Game.player_position.x += 26.0
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
	_draw_mute()
	if flash_time > 0:
		draw_rect(Rect2(0,0,W,H),Color(1,1,0.9,flash_time * 0.7))

func _rect(x: float,y: float,w: float,h: float,color: Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func _round(x: float,y: float,w: float,h: float,color: Color, radius: int = 12) -> void:
	draw_style_box(_style(color,radius),Rect2(x,y,w,h))

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
	var tex: Texture2D = art[name]
	if flip:
		draw_set_transform(Vector2(x+w,y),0.0,Vector2(-1,1))
		draw_texture_rect(tex,Rect2(0,0,w,h),false)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture_rect(tex,Rect2(x,y,w,h),false)

func _button(t: String,box: Rect2,active: bool=true,size: int=24) -> void:
	_round(box.position.x+3,box.position.y+5,box.size.x,box.size.y,Color("#293148"),10)
	_round(box.position.x,box.position.y,box.size.x,box.size.y,Color("#f6d990") if active else Color("#766f75"),10)
	_center(t,box.position.x,box.position.y+box.size.y/2+size*0.37,box.size.x,size,Color("#3d3947") if active else Color.WHITE)

func _draw_title() -> void:
	_rect(0,0,W,H,Color("#24283f"))
	for band in range(12):
		_rect(0,165+band*19,W,20,Color("#c98485").lerp(Color("#594967"),float(band)/12.0))
	draw_circle(Vector2(795,215),55,Color("#ffe1a3"))
	for i in range(26):
		var sx := float((i*139+47)%960)
		var sy := float((i*67+27)%198)
		_rect(sx,sy,3,3,Color("#e9d6c8",0.75))
	_rect(0,285,W,116,Color("#71677f"))
	_rect(0,396,W,144,Color("#585a72"))
	for i in range(14):
		_rect(i*75+12,398,38,4,Color("#b3a0a0"))
	for i in range(22):
		_rect(i*53+((i%3)*11),414+(i%4)*27,18,2,Color("#77798b"))
	_sprite("office",16,257,175,160)
	_sprite("sweets",223,267,155,145)
	_sprite("diner",384,269,150,144)
	_sprite("shop",560,265,155,146)
	_sprite("home",755,255,180,165)
	_sprite("player_front",446,289,85,112)
	_round(115,34,730,182,Color("#31354d"),19)
	_round(124,42,712,165,Color("#fff0cf"),16)
	_center("河俣さんのおうち帰れるかな",138,135,684,43,Color("#61485e"))
	_center("誘惑に負けず、おうちまで帰ろう！",180,183,600,22,Color("#9b6680"))
	_button("ゲームスタート",Rect2(334,435,292,72),true,29)

func _draw_field() -> void:
	for band in range(15):
		_rect(0,band*17,W,18,Color("#30385a").lerp(Color("#bc8384"),float(band)/15.0))
	draw_circle(Vector2(798-camera_x*0.06,80),39,Color("#f7d3a0",0.86))
	for i in range(35):
		var sx := fposmod(float(i*187+39)-camera_x*0.12,W)
		var sy := float((i*61+17)%180)
		_rect(sx,sy,2+(i%3),2+(i%2),Color("#e9ddcf",0.58))
	_rect(0,207,W,52,Color("#626781"))
	_rect(0,260,W,189,Color("#928d98"))
	_rect(0,448,W,92,Color("#4c526d"))
	_rect(0,302,W,4,Color("#d1bcc1"))
	_rect(0,445,W,4,Color("#d1bcc1"))
	for i in range(22):
		var x := i*128.0-camera_x
		_rect(x,459,62,5,Color("#d4c8aa"))
		_rect(x+78,270,45,4,Color("#bab2a3"))
		_rect(x+21,325+(i%2)*47,23,2,Color("#a7a1a7"))
		_rect(x+69,392+(i%3)*12,17,2,Color("#a7a1a7"))
	for i in range(20):
		var x := i*137.0-camera_x
		if x < -180 or x > W+180: continue
		var kind: String = ["houses","tree","sweets","tree","diner","houses","tree","shop"][i%8]
		if kind == "tree":
			_sprite("tree",x+16,167,90,99)
		else:
			_sprite(kind,x,124,136,140)
	for i in range(13):
		var x := i*210.0+160-camera_x
		if x > -30 and x < W+30:
			draw_circle(Vector2(x+18,242),51,Color("#ffe4a3",0.10))
			_sprite("lamp",x,230,36,78)
			_rect(x+10,289,15,3,Color("#ffe4a3"))
	for bench_x in [1180.0,1740.0,2000.0]:
		var bx: float = bench_x-camera_x
		if bx > -80 and bx < W+80:
			_rect(bx,247,92,12,Color("#75556a"))
			_rect(bx+4,261,84,9,Color("#a16c69"))
			_rect(bx+10,270,8,27,Color("#4e4559"))
			_rect(bx+74,270,8,27,Color("#4e4559"))
	_sprite("office",20-camera_x,153,170,148)
	_sprite("home",2380-camera_x,142,174,156)
	for gate in GATES:
		if Game.completed.has(gate.id): continue
		var x: float = gate.x-camera_x
		if x < -50 or x > W+50: continue
		var gy := 319.0 if gate.optional else 361.0
		var pulse := 0.7+0.2*sin(Time.get_ticks_msec()/250.0)
		draw_circle(Vector2(x,gy+14),26,Color(1,0.82,0.48,pulse))
		_sprite(gate.enemy,x-24,gy-16,48,48)
		if gate.optional:
			_text("寄り道",x-23,gy+57,14,Color("#fff4c3"))
	var moving := touch_direction != Vector2.ZERO or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S)
	var direction_name := "side" if absf(player_facing.x) > absf(player_facing.y) else ("front" if player_facing.y > 0 else "back")
	var walk := "player_" + direction_name
	if moving:
		walk += "_walk_a" if int(move_time*8)%2 == 0 else "_walk_b"
	draw_circle(Vector2(Game.player_position.x-camera_x,Game.player_position.y-3),20,Color("#353b53",0.24))
	_sprite(walk,Game.player_position.x-camera_x-29,Game.player_position.y-77,58,76,player_facing.x < 0 and direction_name == "side")
	_draw_hud()
	_draw_pad()
	if Game.player_position.x < 215:
		_round(225,99,370,41,Color("#252d49"),8)
		_text("職場を出た！ おうちまで進もう",239,127,19)
	if Game.completed.has("encounter_08") and Game.player_position.x > 2210:
		_round(350,105,256,38,Color("#252d49"),8)
		_text("おうちの玄関へ！ →",362,132,19)
	if field_notice_time > 0:
		_round(299,145,399,42,Color("#252d49"),8)
		_text(field_notice,312,173,20)

func _draw_hud() -> void:
	_round(13,12,662,81,Color("#222a45"),12)
	_text("Lv.%d" % Game.player_level,25,44,24,Color("#ffe5a9"))
	_draw_meter("HP",Game.current_hp,Game.max_hp,112,22,Color("#7dd8ad"),Game.current_hp <= Game.max_hp*0.25)
	_draw_meter("カロリー",Game.calories,1600,300,22,Color("#f4bc75"),Game.calories >= 1300)
	_draw_meter("やる気",Game.motivation,100,498,22,Color("#9ac8f2"),Game.motivation <= 25)
	_text("戦闘 %d/8～11" % Game.fight_count,737,51,19)

func _draw_meter(label: String,value: int,max_value: int,x: float,y: float,c: Color,warn: bool) -> void:
	_text(("! " if warn else "")+label,x,y+19,17,Color("#ff8388") if warn else Color.WHITE)
	_round(x,y+27,158,12,Color("#454864"),5)
	_round(x,y+27,158.0*clampf(float(value)/max_value,0,1),12,c,5)
	_text("%d / %d" % [value,max_value],x,y+60,17,Color("#ff8588") if warn else Color("#e9e8df"))

func _draw_pad() -> void:
	for entry in _pad_buttons():
		_button(entry[0],entry[1],true,27)

func _pad_buttons() -> Array:
	return [["▲",Rect2(92,284,70,70),Vector2.UP], ["◀",Rect2(15,360,70,70),Vector2.LEFT], ["▶",Rect2(169,360,70,70),Vector2.RIGHT], ["▼",Rect2(92,436,70,70),Vector2.DOWN]]

func _draw_battle() -> void:
	for band in range(15):
		_rect(0,band*17,W,18,Color("#3c4f71").lerp(Color("#dba18d"),float(band)/15.0))
	draw_circle(Vector2(826,76),39,Color("#ffe3b2",0.75))
	for i in range(13):
		var bx := float(i*84)
		var bh := float(36+(i*29)%55)
		_rect(bx,204-bh,79,bh+103,Color("#64738a"))
		for window_x in range(2):
			for window_y in range(2):
				_rect(bx+12+window_x*31,214-bh+window_y*23,13,11,Color("#f4d5a8"))
	_rect(0,266,W,64,Color("#8a929f"))
	for i in range(16):
		_rect(i*64+8,283+(i%2)*23,34,3,Color("#aeb1ae"))
	_rect(0,310,W,230,Color("#eee0cc"))
	draw_circle(Vector2(710,295),104,Color("#6d7283",0.34))
	draw_circle(Vector2(194,302),92,Color("#5e6478",0.33))
	_round(640,76,257,78,Color("#fff0d9"),10)
	_text(enemy.name,655,111,20,Color("#514354"),230)
	_draw_bar(660,124,216,float(enemy_hp)/float(enemy.hp),Color("#e47d7c"))
	_text("HP %d / %d" % [enemy_hp,int(enemy.hp)],657,147,14,Color("#544a5c"))
	var enemy_x := 645.0
	var enemy_y := 153.0
	var scale := 1.0
	if anim_kind == "eat" and anim_time > 0:
		scale = maxf(0.05,anim_time/0.7)
	if anim_kind == "call" and anim_time > 0:
		enemy_x += 220.0*(1-anim_time/0.7)
	if not (anim_kind == "fight" and anim_time > 0 and int(anim_time*18)%2 == 0):
		_sprite(Game.enemy_id,enemy_x+65*(1-scale),enemy_y+80*(1-scale),130*scale,130*scale)
	if anim_kind == "call" and anim_time > 0:
		_round(475,124,42,65,Color("#353954"),5)
		_rect(480,132,32,44,Color("#97c8cc"))
		draw_circle(Vector2(496,182),3,Color("#d3cfcc"))
		_rect(822,170,35,78,Color("#39435d"))
		_rect(820,145,39,38,Color("#dcb18b"))
	var px := 137.0 + (18.0 if anim_kind == "fight" and anim_time > 0 else 0.0)
	_sprite("player_back",px,160,120,151)
	if anim_kind == "eat" and anim_time > 0:
		for i in range(6):
			var sx := px-18+i*39
			var sy := 176.0+18*(i%2)
			draw_line(Vector2(sx-8,sy),Vector2(sx+8,sy),Color("#ffe482"),3)
			draw_line(Vector2(sx,sy-8),Vector2(sx,sy+8),Color("#ffe482"),3)
	_round(32,326,896,202,Color("#26314c"),13)
	_round(42,336,876,182,Color("#fff2da"),10)
	_text("河俣さん  Lv.%d" % Game.player_level,57,368,23,Color("#544658"))
	_text("HP %d/%d   カロリー %d/1600   やる気 %d/100" % [Game.current_hp,Game.max_hp,Game.calories,Game.motivation],303,368,21,Color("#594c57"))
	for i in range(mini(3,battle_text.size())):
		_text(battle_text[maxi(0,battle_text.size()-3)+i],59,394+i*25,18,Color("#594c57"),830)
	if battle_finished:
		_button("つづける  ▶",Rect2(330,449,300,70),true,22)
	else:
		_button("1  戦う",Rect2(58,449,260,70),true,21)
		_button("2  食べる",Rect2(350,449,260,70),true,21)
		_button("3  誰かを呼ぶ",Rect2(642,449,260,70),true,21)

func _draw_bar(x: float,y: float,w: float,p: float,c: Color) -> void:
	_round(x,y,w,10,Color("#9994a2"),5)
	_round(x,y,w*clampf(p,0,1),10,c,5)

func _draw_end(won: bool) -> void:
	_rect(0,0,W,H,Color("#252b42") if won else Color("#483a4a"))
	_rect(0,274,W,266,Color("#665b72") if won else Color("#71616e"))
	if won:
		_rect(0,0,476,276,Color("#d6a58f"))
		_rect(0,276,476,264,Color("#b68f81"))
		_round(37,189,368,157,Color("#827790"),13)
		_round(66,170,312,118,Color("#a191a4"),13)
		_rect(21,90,125,115,Color("#524866"))
		_rect(29,98,109,99,Color("#393f66"))
		_rect(81,98,5,99,Color("#e8ccaa"))
		_sprite("player_seated",220,199,160,163)
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
			_sprite("player_fallen",68,329,160,128)
		else:
			_sprite("player_seated",88,274,150,150)
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
	_button("もう一度遊ぶ" if won else "もう一度",Rect2(335,432,270,72),true,24)
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
		elif screen == "title" and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			_start_game()
		elif screen == "field":
			var key_dir := Vector2.ZERO
			if event.keycode == KEY_LEFT or event.keycode == KEY_A: key_dir = Vector2.LEFT
			elif event.keycode == KEY_RIGHT or event.keycode == KEY_D: key_dir = Vector2.RIGHT
			elif event.keycode == KEY_UP or event.keycode == KEY_W: key_dir = Vector2.UP
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S: key_dir = Vector2.DOWN
			if key_dir != Vector2.ZERO: _nudge(key_dir)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if event.pressed: _pointer_down(event.position)
		else: touch_direction = Vector2.ZERO
	if event is InputEventMouseMotion and mouse_down and screen == "field":
		_set_pad_direction(event.position)
	if event is InputEventScreenTouch:
		if event.pressed: _pointer_down(event.position)
		else: touch_direction = Vector2.ZERO
	if event is InputEventScreenDrag and screen == "field":
		_set_pad_direction(event.position)

func _pointer_down(pos: Vector2) -> void:
	if Rect2(877,9,72,70).has_point(pos):
		muted = not muted
		if muted: music.stop()
		else: music.play()
		queue_redraw()
		return
	match screen:
		"title":
			if Rect2(334,435,292,72).has_point(pos): _start_game()
		"field": _set_pad_direction(pos)
		"battle":
			if battle_finished:
				if Rect2(330,449,300,70).has_point(pos): _battle_command(0)
			else:
				if Rect2(58,449,260,70).has_point(pos): _battle_command(1)
				elif Rect2(350,449,260,70).has_point(pos): _battle_command(2)
				elif Rect2(642,449,260,70).has_point(pos): _battle_command(3)
		"game_over","clear":
			if Rect2(335,432,270,72).has_point(pos): _start_game()
			elif Rect2(631,432,270,72).has_point(pos): screen = "title"; _sound("cancel")

func _set_pad_direction(pos: Vector2) -> void:
	touch_direction = Vector2.ZERO
	for entry in _pad_buttons():
		if entry[1].has_point(pos):
			touch_direction = entry[2]
			_nudge(touch_direction)
			return

func _nudge(direction: Vector2) -> void:
	if screen != "field": return
	var old_x := Game.player_position.x
	player_facing = direction
	Game.player_position += direction * 12.0
	Game.player_position.x = clampf(Game.player_position.x,70.0,WORLD_WIDTH-80.0)
	Game.player_position.y = clampf(Game.player_position.y,285.0,445.0)
	_check_encounter(old_x)

func _start_game() -> void:
	Game.reset()
	screen = "field"
	player_facing = Vector2.RIGHT
	touch_direction = Vector2.ZERO
	field_notice_time = 0
	_sound("select")
