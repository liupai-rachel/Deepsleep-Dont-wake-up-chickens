class_name ArcadeWorld
extends Node2D

const BACKDROP := preload("res://assets/art/coop_backdrop.png")
const CRATE := preload("res://scenes/crate.tscn")
const SCENERY := preload("res://scenes/arcade/scenery.gd")
var arena_size := Vector2(1920,1280)
var bounds := Rect2(64,112,1792,1072)
var solids: Array[Rect2] = []
var nest_points: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var floor_texture: AtlasTexture
var navigation: NavigationRegion2D
var roads: Array[Rect2] = []
var yards: Array[Rect2] = []
var scenery: Array[Node2D] = []
var zones: Array[Dictionary] = []
var actor: CoopPlayer
var terrain_seed := 0
var grid_size := Vector2i(4,3)

func build(level: int, seed_value: int) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = seed_value
	terrain_seed = seed_value
	var factor := 1.0 + (level-1)*0.2
	arena_size = Vector2(1920,1280)*factor
	bounds = Rect2(Vector2(64,112)*factor,Vector2(1792,1072)*factor)
	floor_texture = AtlasTexture.new()
	floor_texture.atlas = BACKDROP
	floor_texture.region = Rect2(600,350,256,192)
	y_sort_enabled = true
	for edge in [Rect2(bounds.position-Vector2(16,16),Vector2(bounds.size.x+32,16)),Rect2(Vector2(bounds.position.x-16,bounds.end.y),Vector2(bounds.size.x+32,16)),Rect2(bounds.position-Vector2(16,0),Vector2(16,bounds.size.y)),Rect2(Vector2(bounds.end.x,bounds.position.y),Vector2(16,bounds.size.y))]:
		_add_collision(edge)
	grid_size = Vector2i(3+level,3+(level-1)/2)
	var cell := bounds.size/Vector2(grid_size)
	for x in range(grid_size.x+1):
		roads.append(Rect2(Vector2(bounds.position.x+x*cell.x-72,bounds.position.y),Vector2(144,bounds.size.y)).intersection(bounds))
	for y in range(grid_size.y+1):
		roads.append(Rect2(Vector2(bounds.position.x,bounds.position.y+y*cell.y-72),Vector2(bounds.size.x,144)).intersection(bounds))
	for row in range(grid_size.y):
		for column in range(grid_size.x):
			var center := bounds.position+(Vector2(column,row)+Vector2.ONE*0.5)*cell
			var kind := (column+row+level+rng.randi_range(0,1))%4
			zones.append({"center":center,"kind":kind})
			_build_plot(center,kind)
	# Alternating hedges leave a clear side of each road for weaving around.
	for column in range(1,grid_size.x):
		for row in range(grid_size.y):
			var point := bounds.position+Vector2(column*cell.x+(-32 if row%2 else 32),(row+0.5)*cell.y)
			_add_scenery(point,2,92,Vector2(60,40))
	for i in range(90+level*24):
		var point := free_point(8)
		if point != Vector2.INF and not is_on_road(point):
			_add_scenery(point,4 if i%5 == 0 else 3,rng.randf_range(20,38))
	for x in range(120,int(arena_size.x)-80,190):
		if absf(x-bounds.get_center().x) < 180: continue
		_add_scenery(Vector2(x,bounds.end.y+75),rng.randi_range(0,1),rng.randf_range(115,145))
		_add_scenery(Vector2(x,bounds.position.y-18),rng.randi_range(0,1),rng.randf_range(115,145))
	for y in range(180,int(bounds.end.y),210):
		_add_scenery(Vector2(bounds.position.x-28,y),rng.randi_range(0,1),125)
		_add_scenery(Vector2(bounds.end.x+28,y),rng.randi_range(0,1),125)
	bake_navigation()
	queue_redraw()

func _build_plot(center: Vector2, kind: int) -> void:
	if kind == 0:
		yards.append(Rect2(center-Vector2(150,112),Vector2(300,224)))
		for offset in [Vector2(-76,-45),Vector2(45,-45),Vector2(-76,45)]: _add_crate(center+offset)
		_add_scenery(center+Vector2(112,65),4,38)
	elif kind == 1:
		for offset in [Vector2(-86,-40),Vector2(70,-60),Vector2(30,70)]:
			_add_scenery(center+offset,rng.randi_range(0,1),rng.randf_range(115,145),Vector2(42,30))
		_add_scenery(center+Vector2(-105,75),2,82,Vector2(58,38))
	elif kind == 2:
		yards.append(Rect2(center-Vector2(155,100),Vector2(310,200)))
		_add_scenery(center+Vector2(-60,-45),5,170,Vector2(145,54))
		_add_scenery(center+Vector2(45,55),5,170,Vector2(145,54))
		_add_scenery(center+Vector2(128,-70),2,78,Vector2(50,34))
	else:
		yards.append(Rect2(center-Vector2(145,100),Vector2(290,200)))
		for offset in [Vector2(-70,-30),Vector2(10,-30)]: _add_scenery(center+offset,2,105,Vector2(74,42))
		_add_crate(center+Vector2(100,65))
		_add_scenery(center+Vector2(-85,80),4,36)

func _add_crate(point: Vector2) -> void:
	var cover := CRATE.instantiate()
	cover.position = point
	add_child(cover)
	solids.append(Rect2(point-Vector2(52,38),Vector2(104,76)))

func _add_scenery(point: Vector2, kind: int, width: float, footprint := Vector2.ZERO) -> void:
	var prop := SCENERY.new()
	prop.position = point
	prop.kind = kind
	prop.display_width = width
	prop.footprint = footprint
	add_child(prop)
	scenery.append(prop)
	if footprint != Vector2.ZERO: solids.append(Rect2(point-footprint*0.5,footprint))

func start_position() -> Vector2:
	return Vector2(bounds.get_center().x,bounds.end.y-45)

func is_on_road(point: Vector2) -> bool:
	for road in roads:
		if road.has_point(point): return true
	return false

func first_nest_point() -> Vector2:
	for radius in [120,170,220,270]:
		for index in range(16):
			var point: Vector2 = start_position()+Vector2.from_angle(index*TAU/16.0)*radius
			if is_free(point,52,true): return point
	return free_point(52,true)

func _add_collision(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.add_to_group("vision_cover")
	body.add_child(collider)
	add_child(body)

func is_free(point: Vector2, padding := 18.0, avoid_nests := false) -> bool:
	if not bounds.grow(-padding).has_point(point): return false
	if point.distance_to(start_position()) < padding+26: return false
	for rect in solids:
		if rect.grow(padding).has_point(point): return false
	if point.distance_to(Vector2(bounds.get_center().x,bounds.position.y+25)) < padding+32: return false
	if avoid_nests:
		for nest in nest_points:
			if nest.distance_to(point) < 55.0 + padding: return false
	return true

func free_point(padding := 18.0, avoid_nests := false) -> Vector2:
	for attempt in range(300):
		var point := Vector2(rng.randf_range(bounds.position.x+padding,bounds.end.x-padding),rng.randf_range(bounds.position.y+padding,bounds.end.y-padding))
		if is_free(point,padding,avoid_nests): return point
	# A bounded grid fallback avoids spawning on a collider after unlucky samples.
	for y in range(int(bounds.position.y+padding),int(bounds.end.y-padding),24):
		for x in range(int(bounds.position.x+padding),int(bounds.end.x-padding),24):
			if is_free(Vector2(x,y),padding,avoid_nests): return Vector2(x,y)
	return Vector2.INF

func step_clear(from: Vector2, to: Vector2) -> bool:
	for step in range(1,7):
		if not is_free(from.lerp(to,float(step)/6),14,true): return false
	return true

func patrol_sector(point: Vector2) -> int:
	return (1 if point.x >= bounds.get_center().x else 0) + (2 if point.y >= bounds.get_center().y else 0)

func patrol_point(sector: int) -> Vector2:
	var area := Rect2(bounds.position+Vector2(sector%2,sector/2)*bounds.size*0.5,bounds.size*0.5).grow(-26)
	for attempt in range(80):
		var point := Vector2(rng.randf_range(area.position.x,area.end.x),rng.randf_range(area.position.y,area.end.y))
		if is_free(point,20,true): return point
	for y in range(int(area.position.y),int(area.end.y),20):
		for x in range(int(area.position.x),int(area.end.x),20):
			if is_free(Vector2(x,y),20,true): return Vector2(x,y)
	return Vector2.INF

func _draw() -> void:
	if floor_texture == null: return
	draw_rect(Rect2(Vector2.ZERO,arena_size),Color("263d34"))
	draw_rect(bounds,Color("52613a"))
	var terrain := RandomNumberGenerator.new()
	terrain.seed = terrain_seed
	for y in range(int(bounds.position.y),int(bounds.end.y),40):
		for x in range(int(bounds.position.x),int(bounds.end.x),40):
			var point := Vector2(x,y)+Vector2(terrain.randf_range(3,25),terrain.randf_range(3,25))
			var color := Color("657343") if terrain.randf() > 0.5 else Color("465a35")
			draw_rect(Rect2(point,Vector2(terrain.randi_range(3,8),3)),color)
			draw_rect(Rect2(point+Vector2(3,-4),Vector2(2,6)),color)
	for yard in yards: _draw_dirt(yard.grow(18))
	for road in roads: _draw_dirt(road)
	_draw_fences()

func _draw_dirt(area: Rect2) -> void:
	for y in range(int(area.position.y),int(area.end.y),96):
		for x in range(int(area.position.x),int(area.end.x),128):
			var size := Vector2(minf(128,area.end.x-x),minf(96,area.end.y-y))
			draw_texture_rect_region(floor_texture,Rect2(Vector2(x,y),size),Rect2(Vector2.ZERO,size*2))

func _draw_fences() -> void:
	for y in [bounds.position.y,bounds.end.y]:
		for offset in [-22,-9]: draw_rect(Rect2(bounds.position.x,y+offset,bounds.size.x,8),Color("56392c"))
		for x in range(int(bounds.position.x),int(bounds.end.x)+1,28):
			draw_rect(Rect2(x-4,y-30,9,34),Color("322731"))
			draw_rect(Rect2(x-2,y-28,5,29),Color("a37a43"))
	for x in [bounds.position.x,bounds.end.x]:
		draw_rect(Rect2(x-6,bounds.position.y,12,bounds.size.y),Color("5c402f"))
		for y in range(int(bounds.position.y),int(bounds.end.y),28):
			draw_rect(Rect2(x-8,y-22,16,26),Color("322731"))
			draw_rect(Rect2(x-5,y-20,10,20),Color("a37a43"))
	for y in [bounds.position.y,bounds.end.y]:
		for x in [bounds.get_center().x-70,bounds.get_center().x+70]:
			draw_circle(Vector2(x,y-18),35,Color(1,0.65,0.15,0.07))
			draw_rect(Rect2(x-7,y-33,14,23),Color("302832"))
			draw_rect(Rect2(x-4,y-29,8,15),Color("eeb94d"))
			draw_rect(Rect2(x-2,y-27,4,10),Color("fff3b1"))

func bake_navigation() -> void:
	navigation = NavigationRegion2D.new()
	add_child(navigation)
	var mesh := NavigationPolygon.new()
	mesh.agent_radius = 16.0
	mesh.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.parsed_collision_mask = 2
	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(mesh,source,self)
	source.add_traversable_outline(PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]))
	NavigationServer2D.bake_from_source_geometry_data(mesh,source)
	navigation.navigation_polygon = mesh
