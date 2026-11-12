class_name ArcadeGame
extends Node2D

const PLAYER := preload("res://scenes/player.tscn")
const AUDIO := preload("res://scenes/round_audio.tscn")
const EFFECT := preload("res://scenes/arcade/effect.gd")
@export_range(10.0,300.0,1.0) var round_seconds := 120.0
@export var use_fixed_seed := false
@export var fixed_seed := 7
var profile: ArcadeProfile
var selected_level := 1
var current_level := 1
var running := false
var score := 0
var collected := 0
var chain := 0
var combo_left := 0.0
var time_left := 120.0
var world: ArcadeWorld
var player: CoopPlayer
var ui: ArcadeUI
var camera: Camera2D
var audio: CoopRoundAudio
var eggs: Array[ArcadeEgg] = []
var nests: Array[ArcadeNest] = []
var hens: Array[ArcadeHen] = []
var spawn_left := 0.0
var golden_count := 0
var last_result := {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if profile == null:
		profile = ArcadeProfile.new()
		profile.load_progress()
	selected_level = profile.unlocked
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.getElementById('canvas').addEventListener('contextmenu',function(event){event.preventDefault();});")
	_rng.randomize()
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	ui = ArcadeUI.new()
	ui.round_duration = ceili(round_seconds)
	add_child(ui)
	ui.start_requested.connect(begin_round)
	ui.pause_requested.connect(toggle_pause)
	ui.abandon_requested.connect(abandon_round)
	ui.selection_changed.connect(_select_level)
	ui.upgrade_requested.connect(_buy_upgrade)
	audio = AUDIO.instantiate()
	add_child(audio)
	audio.get_node("Egg").max_polyphony = 8
	_build_world(selected_level)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	ui.show_menu(profile,selected_level)
	_update_hud()

func _select_level(level: int) -> void:
	if running or level < 1 or level > profile.unlocked: return
	selected_level = level
	_build_world(level)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	ui.show_menu(profile,selected_level,last_result)
	_update_hud()

func _buy_upgrade(index: int) -> void:
	if running: return
	profile.buy(index)
	ui.show_menu(profile,selected_level,last_result)

func _build_world(level: int) -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	eggs.clear()
	nests.clear()
	hens.clear()
	world = ArcadeWorld.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var seed_value := fixed_seed if use_fixed_seed else _rng.randi()
	world.build(level,seed_value)
	current_level = level
	camera.position = world.arena_size * 0.5
	camera.zoom = Vector2.ONE * 960.0 / world.arena_size.x
	player = PLAYER.instantiate()
	player.position = Vector2(world.bounds.get_center().x,world.bounds.end.y-45)
	player.move_speed = 330.0
	world.add_child(player)
	for i in range(2 + level*2):
		var point := world.free_point(52,true)
		if point == Vector2.INF: break
		world.nest_points.append(point)
		var nest := ArcadeNest.new()
		nest.position = point
		nest.rng.seed = world.rng.randi()
		nest.refill_speed = pow(0.86,profile.upgrades[2])
		world.add_child(nest)
		nests.append(nest)
	for i in range(2+level): _add_hen(false)
	_spawn_batch(18+level*14)

func begin_round(level: int) -> void:
	if running: return
	if level < 1 or level > profile.unlocked: return
	get_tree().paused = false
	running = false
	_build_world(level)
	selected_level = level
	score = 0
	collected = 0
	chain = 0
	combo_left = 0.0
	golden_count = 0
	time_left = round_seconds
	spawn_left = world.rng.randf_range(0.4,0.9)
	last_result = {}
	running = true
	ui.hide_menu()
	ui.announce("右键点蛋或连点鸡窝，开始收集！","Right-click eggs or nests to start collecting!")
	_update_hud()

func _process(delta: float) -> void:
	if not running or get_tree().paused: return
	time_left = maxf(0,time_left-delta)
	if time_left <= 0:
		finish_round()
		return
	combo_left = maxf(0,combo_left-delta)
	if combo_left == 0: chain = 0
	spawn_left -= delta
	if spawn_left <= 0:
		var desired := 18+current_level*14
		var count := world.rng.randi_range(2,5)
		if eggs.size() < desired/2: count += 6
		_spawn_batch(count)
		spawn_left = world.rng.randf_range(0.45,1.1)
	var elapsed := round_seconds-time_left
	if current_level >= 3 and golden_count == 0 and elapsed >= round_seconds*0.5:
		_add_hen(true)
		golden_count = 1
		ui.announce("黄金鸡来了！它留下的金蛋价值更高。","Golden hen! Follow the high-value golden eggs.")
		audio.play_cue(&"Success")
	if current_level == 4 and golden_count == 1 and elapsed >= round_seconds*0.75:
		_add_hen(true)
		golden_count = 2
		ui.announce("第二只黄金鸡加入了农场！","A second golden hen has arrived!")
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_round"):
		if running: toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if not running or get_tree().paused: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		collect_at(get_canvas_transform().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func collect_at(point: Vector2) -> bool:
	if not running or get_tree().paused: return false
	var closest: ArcadeEgg
	var distance := pow(maxf(14,12/camera.zoom.x),2)
	for egg in eggs:
		if egg.claimed: continue
		var candidate := egg.position.distance_squared_to(point)
		if candidate <= distance:
			distance = candidate
			closest = egg
	if closest != null:
		var origin := closest.position
		_collect_egg(closest)
		if profile.upgrades[0] > 0:
			var radius: float = (18 + profile.upgrades[0]*12) / camera.zoom.x
			for other: ArcadeEgg in eggs.duplicate():
				if other.position.distance_squared_to(origin) <= radius*radius: _collect_egg(other)
		return true
	for nest in nests:
		if Rect2(nest.position+Vector2(-47,-70),Vector2(94,114)).has_point(point):
			if nest.take():
				_award(nest.position+Vector2(0,-8),false)
				return true
			ui.announce("这处鸡窝正在补货，先捡地面的蛋吧。","Nest refilling. Pick up some ground eggs meanwhile.")
			return false
	return false

func _collect_egg(egg: ArcadeEgg) -> void:
	if egg.claimed or not eggs.has(egg): return
	egg.claimed = true
	eggs.erase(egg)
	_award(egg.position,egg.golden)
	egg.queue_free()

func _award(point: Vector2, gold: bool) -> void:
	var units := 2 if world.rng.randf() < profile.upgrades[1]*0.1 else 1
	chain += 1
	combo_left = 2.2
	var points := units * (5 if gold else 1) * multiplier()
	score += points
	collected += units
	var effect := Node2D.new()
	effect.set_script(EFFECT)
	effect.origin = point
	effect.target = player
	effect.golden = gold
	effect.number = points
	effect.z_index = 5
	world.add_child(effect)
	player.show_feed_toss()
	audio.get_node("Egg").pitch_scale = minf(1.65,1.0+chain*0.012)
	audio.play_cue(&"Egg")
	_update_hud()

func multiplier() -> int:
	return 1 + mini(3,chain/12)

func _add_hen(gold: bool) -> void:
	var point := world.free_point(24,true)
	if point == Vector2.INF: return
	var hen := ArcadeHen.new()
	hen.world = world
	hen.golden = gold
	hen.position = point
	hen.egg_laid.connect(_spawn_egg_at)
	world.add_child(hen)
	hens.append(hen)

func _spawn_batch(count: int) -> void:
	var maximum := 48+current_level*18
	for i in range(count):
		if eggs.size() >= maximum: break
		var point := world.free_point(16,true)
		if point == Vector2.INF: break
		var clear := true
		for egg in eggs:
			if egg.position.distance_to(point) < 20:
				clear = false
				break
		if clear: _spawn_egg_at(point,false)

func _spawn_egg_at(point: Vector2, gold: bool) -> void:
	if not world.is_free(point,12,true): return
	if eggs.size() >= 48+current_level*18:
		if not gold: return
		var replaced := false
		for old in eggs:
			if not old.golden:
				eggs.erase(old)
				old.queue_free()
				replaced = true
				break
		if not replaced: return
	var egg := ArcadeEgg.new()
	egg.position = point
	egg.golden = gold
	egg.phase = world.rng.randf()*TAU
	egg.scale = Vector2.ONE * maxf(1.0,0.85/camera.zoom.x)
	egg.z_index = 1
	world.add_child(egg)
	eggs.append(egg)

func toggle_pause() -> void:
	if not running: return
	get_tree().paused = not get_tree().paused
	if get_tree().paused: ui.show_menu(profile,current_level,{},true)
	else: ui.hide_menu()

func abandon_round() -> void:
	get_tree().paused = false
	running = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	ui.show_menu(profile,selected_level)

func finish_round() -> void:
	if not running: return
	running = false
	get_tree().paused = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	last_result = profile.settle(current_level,score)
	last_result["eggs"] = collected
	selected_level = mini(current_level+1,profile.unlocked)
	audio.play_cue(&"Success")
	ui.show_menu(profile,selected_level,last_result)
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(ui): ui.update_game(score,collected,chain,multiplier(),combo_left,time_left,current_level)
