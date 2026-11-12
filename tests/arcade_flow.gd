extends SceneTree

var failures := 0
const SAVE_PATH := "user://arcade-regression-only.json"

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(frames: int) -> void:
	for i in range(frames): await process_frame

func click(game: ArcadeGame, button: int, point: Vector2) -> void:
	var screen_point := game.get_canvas_transform() * point
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = screen_point
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	root.size = Vector2i(960,540)
	var profile := ArcadeProfile.new()
	profile.save_path = SAVE_PATH
	var game: ArcadeGame = load("res://scenes/arcade/game.tscn").instantiate()
	game.profile = profile
	game.use_fixed_seed = true
	root.add_child(game)
	await tick(3)
	expect(game.ui.overlay.visible and not game.running,"Start menu must be visible before the timer starts")
	game.begin_round(1)
	await tick(3)
	game.begin_round(4)
	expect(game.current_level == 1,"Locked stages must not start")
	expect(game.eggs.size() >= 20,"The first round must start with plentiful ground eggs")
	expect(game.nests.size() >= 4,"Random nests should be available")
	var egg: ArcadeEgg = game.eggs[0]
	var point := egg.position
	game.player.position = point
	await tick(8)
	expect(game.collected == 0,"Walking onto eggs must not auto-collect")
	await click(game,MOUSE_BUTTON_LEFT,point)
	expect(game.collected == 0,"Left click must not pick up eggs")
	await click(game,MOUSE_BUTTON_RIGHT,point)
	expect(game.collected == 1 and game.score == 1,"Right click must immediately collect and score")
	var unchanged := game.score
	game.collect_at(point)
	expect(game.score == unchanged,"A removed egg cannot be collected again")
	var nest: ArcadeNest = game.nests[0]
	var stock := nest.stock
	var collected_before := game.collected
	for i in range(stock): expect(game.collect_at(nest.position),"Each nest click should immediately yield one egg")
	expect(game.collected == collected_before+stock and nest.stock == 0,"Visible nest stock must decrease with every click")
	expect(not game.collect_at(nest.position),"Empty nests must not yield phantom eggs")
	# Clearing the field should not grant any collection and must be replenished.
	for other: ArcadeEgg in game.eggs.duplicate():
		game.eggs.erase(other)
		other.queue_free()
	collected_before = game.collected
	await tick(500)
	expect(game.eggs.size() > 0 and game.eggs.size() <= 66,"Random spawning must replenish eggs and respect a cap")
	expect(game.collected == collected_before,"Spawning must not count as collecting")
	expect(nest.stock >= 2 and nest.stock <= 6,"Empty nests must refill with a visible random stock")
	var time_before := game.time_left
	game.toggle_pause()
	await tick(5)
	expect(is_equal_approx(game.time_left,time_before),"Pausing must stop the round timer")
	expect(not game.collect_at(game.eggs[0].position),"Paused rounds must not collect")
	game.toggle_pause()
	# Settlement is once per completed round; score is independent from currency.
	game.score = 125
	game.collected = 80
	game.time_left = 0.01
	game._process(0.02)
	expect(not game.running and game.ui.overlay.visible,"Timeout must open settlement instead of failing the run")
	expect(profile.coins == 25 and profile.best[0] == 125 and profile.unlocked == 2,"Settlement must award currency, best score and next stage")
	game.finish_round()
	expect(profile.coins == 25,"Settlement must not award twice")
	expect(profile.buy(0) and profile.coins == 5 and profile.upgrades[0] == 1,"A purchased upgrade must spend currency and persist a level")
	expect(not profile.buy(1),"Insufficient funds must not buy an upgrade")
	var reloaded := ArcadeProfile.new()
	reloaded.save_path = SAVE_PATH
	reloaded.load_progress()
	expect(reloaded.coins == 5 and reloaded.upgrades[0] == 1 and reloaded.best[0] == 125,"Progress must survive reloading")
	var prior_area: float = game.world.arena_size.x*game.world.arena_size.y
	for level in range(2,5):
		game.begin_round(level)
		await tick(3)
		var area: float = game.world.arena_size.x*game.world.arena_size.y
		expect(area > prior_area,"Each unlocked stage must have a physically larger world")
		prior_area = area
		for ground: ArcadeEgg in game.eggs:
			expect(game.world.is_free(ground.position,12,true),"Eggs must not spawn inside obstacles or nests")
		if level == 2:
			var gather_point := game.world.free_point(20,true)
			for attempt in range(100):
				if game.world.is_free(gather_point+Vector2(20,0),12,true): break
				gather_point = game.world.free_point(20,true)
			game._spawn_egg_at(gather_point,false)
			game._spawn_egg_at(gather_point+Vector2(20,0),false)
			var before := game.collected
			game.collect_at(gather_point)
			expect(game.collected >= before+2,"Gather upgrade must collect adjacent eggs from one manual click")
		if level >= 3:
			game._process(59.0)
			expect(game.golden_count == 0,"Golden hens should not appear before halfway")
			game._process(2.0)
			expect(game.golden_count == 1,"Later stages should introduce a golden hen after halfway")
			game._spawn_batch(1000)
			var target := game.world.free_point(18,true)
			game._spawn_egg_at(target,true)
			var gold: ArcadeEgg
			for candidate in game.eggs:
				if candidate.golden: gold = candidate
			expect(gold != null,"A full ordinary field must still allow golden eggs")
			if gold != null:
				var old_score := game.score
				game.collect_at(gold.position)
				expect(game.score >= old_score+5,"Golden eggs must be worth more")
		if level == 4:
			game._process(30.0)
			expect(game.golden_count == 2,"Final stage should add a second golden hen later")
		game.finish_round()
		await tick(2)
	# Corrupt/old saves should recover to safe defaults rather than crash.
	var bad := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	bad.store_string("bad json")
	bad.close()
	var recovered := ArcadeProfile.new()
	recovered.save_path = SAVE_PATH
	recovered.load_progress()
	expect(recovered.coins == 0 and recovered.unlocked == 1,"Corrupt save should fall back to defaults")
	game.audio.stop_all()
	OS.delay_msec(200)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(SAVE_PATH)
	if failures == 0: print("PASS: manual right-click collection, visible nest stocks, spawning, pause, timeout settlement, saved upgrades, four growing stages and golden hens")
	quit(1 if failures > 0 else 0)
