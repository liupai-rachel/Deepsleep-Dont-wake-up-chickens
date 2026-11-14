class_name ArcadeWorld
extends Node2D

const BACKDROP := preload("res://assets/art/coop_backdrop.png")
const CRATE := preload("res://scenes/crate.tscn")
var theme_index := 1
var cover_props: Array[int] = []
var arena_size := Vector2(960,540)
var bounds := Rect2(36,74,888,404)
var solids: Array[Rect2] = []
var nest_points: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var floor_texture: AtlasTexture
var navigation: NavigationRegion2D

func build(level: int, seed_value: int) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = seed_value
	arena_size = Vector2(960,540) * (1.0 + (level-1)*0.2)
	var factor := 1.0 + (level-1)*0.2
	bounds = Rect2(Vector2(36,74)*factor,Vector2(888,404)*factor)
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKDROP
	backdrop.centered = false
	backdrop.scale = arena_size / BACKDROP.get_size()
	backdrop.z_index = -10
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var projection := ShaderMaterial.new()
	projection.shader = preload("res://assets/art/coop_projection.gdshader")
	projection.set_shader_parameter("theme_tint",[Vector3.ONE,Vector3(0.90,1.03,0.90),Vector3(0.68,0.98,1.03),Vector3(0.97,0.91,0.83)][theme_index-1])
	backdrop.material = projection
	add_child(backdrop)
	floor_texture = AtlasTexture.new()
	floor_texture.atlas = BACKDROP
	floor_texture.region = Rect2(600,350,256,192)
	y_sort_enabled = true
	for edge in [Rect2(bounds.position-Vector2(16,16),Vector2(bounds.size.x+32,16)),Rect2(Vector2(bounds.position.x-16,bounds.end.y),Vector2(bounds.size.x+32,16)),Rect2(bounds.position-Vector2(16,0),Vector2(16,bounds.size.y)),Rect2(Vector2(bounds.end.x,bounds.position.y),Vector2(16,bounds.size.y))]:
		_add_collision(edge)
	var desired := 2 + level*2
	for index in range(desired):
		var point := free_point(72)
		if point == Vector2.INF: break
		var cover := CRATE.instantiate()
		cover.position = point
		var prop := -1
		if theme_index == 2: prop = 2 if index%3 != 2 else -1
		elif theme_index == 3: prop = [1,5,-1][index%3]
		elif theme_index == 4: prop = [3,-1,6][index%3]
		cover_props.append(prop)
		if prop >= 0:
			var old := cover.get_node("Art")
			cover.remove_child(old)
			old.queue_free()
			if prop == 1: cover.add_child(FarmProps.sprite(5,110,38))
			cover.add_child(FarmProps.sprite(prop,144,38))
		add_child(cover)
		solids.append(Rect2(point-Vector2(52,38),Vector2(104,76)))
	_decorate_edges(factor)
	bake_navigation()
	queue_redraw()

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
	if point.distance_to(Vector2(bounds.get_center().x,bounds.end.y-45)) < padding+26: return false
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
	for y in range(int(bounds.position.y),int(bounds.end.y),96):
		for x in range(int(bounds.position.x),int(bounds.end.x),128):
			var size := Vector2(minf(128,bounds.end.x-x),minf(96,bounds.end.y-y))
			draw_texture_rect_region(floor_texture,Rect2(Vector2(x,y),size),Rect2(Vector2.ZERO,size*2),[Color.WHITE,Color(0.82,1.0,0.85),Color(0.63,0.94,0.93),Color(0.94,0.83,0.72)][theme_index-1])

func _decorate_edges(factor: float) -> void:
	if theme_index == 1: return
	var prop := 4 if theme_index == 2 else (1 if theme_index == 3 else 3)
	for x in [95,245,715,865]:
		var holder := Node2D.new()
		holder.position = Vector2(x,84)*factor
		holder.add_child(FarmProps.sprite(prop,(82 if theme_index == 3 else 125)*factor))
		add_child(holder)
	for side in [0,1]:
		for y in [180,320,455]:
			var holder := Node2D.new()
			holder.position = Vector2(24 if side == 0 else 936,y)*factor
			holder.add_child(FarmProps.sprite(prop,(72 if theme_index == 3 else 84)*factor))
			add_child(holder)
	for x in [130,320,660,840]:
		var holder := Node2D.new()
		holder.position = Vector2(x,512)*factor
		holder.add_child(FarmProps.sprite(7 if theme_index == 2 else (5 if theme_index == 3 else 6),100*factor))
		add_child(holder)

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
