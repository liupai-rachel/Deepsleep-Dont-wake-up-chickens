extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(frames: int) -> void:
	for i in range(frames): await process_frame

func run() -> void:
	root.size = Vector2i(960,540)
	var game: ArcadeGame = load("res://scenes/arcade/game.tscn").instantiate()
	game.profile = ArcadeProfile.new()
	game.profile.unlocked = 4
	game.use_fixed_seed = true
	game.guards_enabled = false
	root.add_child(game)
	await tick(3)
	for level in range(1,5):
		for seed_value in [7,19]:
			game.fixed_seed = seed_value
			game.begin_round(level)
			await tick(4)
			var view_size := Vector2(960,540)/game.camera.zoom
			expect(game.world.arena_size.x > view_size.x*2 and game.world.arena_size.y > view_size.y*2,"The follow camera must reveal only a local portion of every stage")
			expect(game.camera.zoom.is_equal_approx(Vector2.ONE*1.08),"Later stages must retain the same close view instead of fitting the entire map")
			expect(game.world.zones.size() >= 12 and game.world.solids.size() >= 35,"The farm must have multiple plots and meaningful cover")
			expect(game.world.scenery.size() >= 65,"The world must include abundant foliage scenery")
			expect(game.nests[0].position.distance_to(game.world.start_position()) <= 285,"A first nest should be discoverable near the starting view")
			expect(game.eggs.size() >= game.egg_target()*0.8,"Ground eggs must scale with the larger farm")
			var map := game.world.get_world_2d().navigation_map
			# Baked boundaries can project a target a few pixels onto the nav polygon.
			for i in range(24):
				var point := game.world.free_point(20)
				var path := NavigationServer2D.map_get_path(map,game.world.start_position(),point,true)
				expect(not path.is_empty() and path[-1].distance_to(point) < 4,"All sampled plot locations must connect to the entrance (stage %d, seed %d, target %s, end %s)" % [level,seed_value,point,path[-1] if not path.is_empty() else Vector2.INF])
			for nest in game.nests:
				var path := NavigationServer2D.map_get_path(map,game.world.start_position(),nest.position,true)
				expect(not path.is_empty() and path[-1].distance_to(nest.position) < 4,"Every nest must be accessible around cover (stage %d, seed %d, target %s, end %s)" % [level,seed_value,nest.position,path[-1] if not path.is_empty() else Vector2.INF])
			var cell := game.world.bounds.size/Vector2(game.world.grid_size)
			for column in range(1,game.world.grid_size.x):
				for row in range(1,game.world.grid_size.y):
					var junction := game.world.bounds.position+Vector2(column,row)*cell
					var path := NavigationServer2D.map_get_path(map,game.world.start_position(),junction,true)
					expect(not path.is_empty() and path[-1].distance_to(junction) < 2,"Connecting road junctions must remain open")
			for corner in [game.world.bounds.position+Vector2(30,30),game.world.bounds.end-Vector2(30,30)]:
				game.player.position = corner
				game.update_camera(true)
				var center := game.camera.get_screen_center_position()
				var visible := Rect2(center-view_size*0.5,view_size)
				expect(visible.position.x >= -2 and visible.position.y >= -2 and visible.end.x <= game.world.arena_size.x+2 and visible.end.y <= game.world.arena_size.y+2,"Camera limits must prevent viewing beyond the world")
			print("Connected stage ",level," seed ",seed_value,": ",game.world.zones.size()," plots, ",game.world.solids.size()," obstacles")
			game.abandon_round()
	game.begin_round(1)
	await tick(4)
	var initial_camera := game.camera.get_screen_center_position()
	var initial_player := game.player.position
	Input.action_press("move_right")
	await tick(36)
	Input.action_release("move_right")
	await tick(3)
	expect(game.player.position.x > initial_player.x+100,"The south lane must permit real keyboard movement")
	expect(game.camera.get_screen_center_position().x > initial_camera.x+90,"The camera must actually track walking, rather than stay at map center")
	var player_screen := game.get_canvas_transform()*game.player.position
	expect(Rect2(150,70,660,400).has_point(player_screen),"The moving player must stay comfortably inside the view")
	var target := game.player.position+Vector2(30,-10)
	for offset in [Vector2(30,-10),Vector2(-25,0),Vector2(20,-25),Vector2(0,-35)]:
		var candidate: Vector2 = game.player.position+offset
		if game.world.is_free(candidate,12,true) and game.can_collect_point(candidate):
			target = candidate
			break
	game._spawn_egg_at(target,false)
	var before_pickup := game.collected
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.get_canvas_transform()*target+Vector2(0,16)
	Input.parse_input_event(click)
	await process_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await process_frame
	expect(game.collected > before_pickup,"Screen clicks must still pick nearby eggs after the camera pans")
	game.toggle_pause()
	var paused_camera := game.camera.get_screen_center_position()
	await tick(10)
	expect(game.camera.get_screen_center_position().is_equal_approx(paused_camera),"Pausing must freeze camera motion")
	game.toggle_pause()
	for prop in game.world.scenery:
		if prop.kind <= 1:
			game.player.position = prop.position+Vector2(0,-60)
			await tick(10)
			expect(prop.art.modulate.a < 0.7,"A canopy covering the player must fade")
			game.player.position = prop.position+Vector2(180,40)
			await tick(10)
			expect(prop.art.modulate.a > 0.9,"The canopy should recover after the player leaves")
			break
	game.queue_free()
	await tick(2)
	if failures == 0: print("PASS: eight connected farm layouts, close follow camera, world limits, movement/pause tracking, accessible nests and fading canopies")
	quit(1 if failures else 0)
