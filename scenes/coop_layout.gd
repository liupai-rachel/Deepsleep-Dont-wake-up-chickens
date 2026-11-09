class_name CoopLayout
extends Node

signal prepared(success: bool)

const WALL_SCENE := preload("res://scenes/interior_wall.tscn")
const GRID_SIZE := Vector2i(15, 7)
const GRID_ORIGIN := Vector2(88, 108)
const CELL_SIZE := 56.0
const CLEARANCE := 18.0
const FLOOR_BOUNDS := Rect2(36, 74, 888, 404)
const ENTRY_ZONE := Rect2(398, 360, 164, 118)
const FARMER_ZONE := Rect2(388, 74, 184, 64)
const CARDINAL := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

class Plan:
	var crates := PackedVector2Array()
	var walls: Array[Rect2] = []
	var nests := PackedVector2Array()
	var supplies := PackedVector2Array()
	var hen_spawns := PackedVector2Array()
	var routes: Array[PackedVector2Array] = []
	var player := Vector2.ZERO
	var farmer := Vector2.ZERO

@export var use_fixed_layout := false
@export_range(0, 30, 1) var generation_attempts := 12

var _rng := RandomNumberGenerator.new()
var _fixed_plan: Plan
var _seed_value := 0
var _attempts_left := 0
var _using_fixed := false
var _frames_left := 0
var _previous_map_iteration := 0
var _previous_region_iteration := 0

@onready var _level := get_parent()
@onready var _crates := _level.get_node("Crates").get_children()
@onready var _nests := _level.get_node("Nests").get_children()
@onready var _supplies := _level.get_node("Feed/Supplies").get_children()
@onready var _hens := _level.get_node("Chickens").get_children()
@onready var _player: CoopPlayer = _level.get_node("Player")
@onready var _farmer: Marker2D = _level.get_node("FarmerEntrance")
@onready var _exit: Area2D = _level.get_node("Exit")
@onready var _walls: Node2D = _level.get_node("InteriorWalls")
@onready var _region: NavigationRegion2D = _level.get_node("WalkNavigation")
@onready var _floor: Polygon2D = _level.get_node("Floor")


func _ready() -> void:
	set_physics_process(false)


func prepare(seed_value: int, egg_goal: int) -> void:
	var total_eggs := 0
	for nest: CoopNest in _nests:
		total_eggs += nest.eggs_left
	if total_eggs < egg_goal:
		push_error("Layout seed %d has insufficient eggs." % seed_value)
		prepared.emit(false)
		return

	_seed_value = seed_value
	_fixed_plan = _capture_fixed_plan()
	_rng.seed = seed_value ^ 0x4c41594f
	_attempts_left = 0 if use_fixed_layout else generation_attempts
	_try_next_layout()


func _try_next_layout() -> void:
	while _attempts_left > 0:
		_attempts_left -= 1
		var plan := _generate(_rng)
		if plan != null:
			_activate(plan)
			return

	if _using_fixed:
		push_error("The fixed coop failed validation for seed %d." % _seed_value)
		set_physics_process(false)
		prepared.emit(false)
		return

	_using_fixed = true
	if not use_fixed_layout:
		push_warning("Layout seed %d exhausted %d attempts. Using the fixed layout." % [_seed_value, generation_attempts])
	_activate(_fixed_plan)


func _physics_process(_delta: float) -> void:
	var map := _region.get_world_2d().navigation_map
	var region_id := _region.get_rid()
	var synchronized := (
		NavigationServer2D.map_get_iteration_id(map) != _previous_map_iteration
		and NavigationServer2D.region_get_iteration_id(region_id) != _previous_region_iteration
	)
	if synchronized and NavigationServer2D.map_get_closest_point_owner(map, _player.global_position) == region_id and _verify_navigation(map):
		if _opening_is_safe():
			set_physics_process(false)
			prepared.emit(true)
			return
		_frames_left = 0

	_frames_left -= 1
	if _frames_left <= 0:
		if not _using_fixed:
			push_warning("Layout seed %d attempt %d failed final validation." % [_seed_value, generation_attempts - _attempts_left])
		_try_next_layout()


func _generate(rng: RandomNumberGenerator) -> Plan:
	if _crates.size() != 3 or _hens.size() != 2:
		return null
	for hen: CoopChicken in _hens:
		if hen.patrol_points.size() != 4:
			return null

	var plan := Plan.new()
	var solids: Array[Rect2] = []
	var crate_shape: RectangleShape2D = _crates[0].get_node("CollisionShape2D").shape
	var crate_size := crate_shape.size
	for first_column in [2, 6, 10]:
		var options: Array[Rect2] = []
		for column in range(first_column, first_column + 2):
			for row in range(1, 4):
				var center := _point(Vector2i(column, row)) + Vector2.ONE * CELL_SIZE * 0.5
				var area := _centered(center, crate_size)
				if _can_place_cover(area, solids):
					options.append(area)
		if options.is_empty():
			return null
		var selected := options[rng.randi_range(0, options.size() - 1)]
		solids.append(selected)
		plan.crates.append(selected.get_center())

	for wall in range(2):
		var options: Array[Rect2] = []
		for column in range(1, GRID_SIZE.x - 1):
			for row in range(1, GRID_SIZE.y - 1):
				var point := _point(Vector2i(column, row))
				var horizontal := _centered(point + Vector2(CELL_SIZE * 0.5, 0), Vector2(104, 24))
				var vertical := _centered(point + Vector2(0, CELL_SIZE * 0.5), Vector2(24, 104))
				for area in [horizontal, vertical]:
					if _can_place_cover(area, solids):
						options.append(area)
		if options.is_empty():
			return null
		var selected := options[rng.randi_range(0, options.size() - 1)]
		solids.append(selected)
		plan.walls.append(selected)

	var player_cell := Vector2i(rng.randi_range(6, 8), 5)
	var farmer_cell := Vector2i(rng.randi_range(6, 8), 0)
	plan.player = _point(player_cell)
	plan.farmer = _point(farmer_cell)
	var reachable := _reachable_cells(player_cell, solids)
	var exit_cell := Vector2i(7, 6)
	if not reachable.has(farmer_cell) or not reachable.has(exit_cell):
		return null
	if not _segment_clear(_point(exit_cell), _exit.position, solids):
		return null

	var reserved: Array[Rect2] = [ENTRY_ZONE, FARMER_ZONE]
	for index in range(_hens.size()):
		var hen: CoopChicken = _hens[index]
		var route := _pick_patrol(rng, index, hen.vision_distance, reachable, solids)
		if route.is_empty():
			return null
		plan.hen_spawns.append(route[-1])
		plan.routes.append(route)
		for point in route:
			reserved.append(_centered(point, Vector2(36, 36)))

	plan.nests = _pick_items(rng, _nests.size(), Vector2(64, 42), reachable, solids, reserved)
	plan.supplies = _pick_items(rng, _supplies.size(), Vector2(28, 28), reachable, solids, reserved)
	if plan.nests.size() != _nests.size() or plan.supplies.size() != _supplies.size():
		return null
	return plan


func _can_place_cover(area: Rect2, solids: Array[Rect2]) -> bool:
	if not FLOOR_BOUNDS.encloses(area.grow(CLEARANCE * 2.0)):
		return false
	if area.grow(CLEARANCE).intersects(ENTRY_ZONE) or area.grow(CLEARANCE).intersects(FARMER_ZONE):
		return false
	for other in solids:
		if area.grow(CLEARANCE).intersects(other.grow(CLEARANCE)):
			return false
	return true


func _reachable_cells(start: Vector2i, solids: Array[Rect2]) -> Dictionary:
	var visited := {start: true}
	var frontier: Array[Vector2i] = [start]
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		for direction: Vector2i in CARDINAL:
			var next := current + direction
			if not Rect2i(Vector2i.ZERO, GRID_SIZE).has_point(next) or visited.has(next):
				continue
			if _segment_clear(_point(current), _point(next), solids):
				visited[next] = true
				frontier.append(next)
	return visited


func _pick_patrol(rng: RandomNumberGenerator, side: int, vision_range: float, reachable: Dictionary, solids: Array[Rect2]) -> PackedVector2Array:
	var routes: Array[PackedVector2Array] = []
	var first_column := 0 if side == 0 else 9
	for column in range(first_column, first_column + 4):
		for row in range(5):
			for height in [1, 2]:
				var corners := [
					Vector2i(column, row), Vector2i(column + 2, row),
					Vector2i(column + 2, row + height), Vector2i(column, row + height),
				]
				var clear := true
				for index in range(corners.size()):
					if not reachable.has(corners[index]) or not _segment_clear(_point(corners[index]), _point(corners[(index + 1) % 4]), solids):
						clear = false
						break
				if not clear:
					continue
				for start in range(4):
					var spawn := _point(corners[start])
					if spawn.distance_to(spawn.clamp(ENTRY_ZONE.position, ENTRY_ZONE.end)) <= vision_range + 6.0:
						continue
					var route := PackedVector2Array()
					for offset in range(1, 5):
						route.append(_point(corners[(start + offset) % 4]))
					routes.append(route)
	if routes.is_empty():
		return PackedVector2Array()
	return routes[rng.randi_range(0, routes.size() - 1)]


func _pick_items(rng: RandomNumberGenerator, count: int, size: Vector2, reachable: Dictionary, solids: Array[Rect2], reserved: Array[Rect2]) -> PackedVector2Array:
	var selected := PackedVector2Array()
	for item in count:
		var options := PackedVector2Array()
		for cell: Vector2i in reachable:
			var point := _point(cell)
			var area := _centered(point, size)
			if not FLOOR_BOUNDS.encloses(area):
				continue
			if not _overlaps(area, solids) and not _overlaps(area, reserved):
				options.append(point)
		if options.is_empty():
			break
		var point := options[rng.randi_range(0, options.size() - 1)]
		selected.append(point)
		reserved.append(_centered(point, size))
	return selected


func _segment_clear(from: Vector2, to: Vector2, solids: Array[Rect2]) -> bool:
	var span := Rect2(from, Vector2.ZERO).expand(to).grow(CLEARANCE)
	return FLOOR_BOUNDS.encloses(span) and not _overlaps(span, solids)


func _overlaps(area: Rect2, others: Array[Rect2]) -> bool:
	for other in others:
		if area.intersects(other, true):
			return true
	return false


func _point(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE


func _centered(point: Vector2, size: Vector2) -> Rect2:
	return Rect2(point - size * 0.5, size)


func _capture_fixed_plan() -> Plan:
	var plan := Plan.new()
	plan.player = _player.position
	plan.farmer = _farmer.position
	for crate: Node2D in _crates:
		plan.crates.append(crate.position)
	for nest: Node2D in _nests:
		plan.nests.append(nest.position)
	for supply: Node2D in _supplies:
		plan.supplies.append(supply.position)
	for hen: CoopChicken in _hens:
		plan.hen_spawns.append(hen.position)
		var route := PackedVector2Array()
		for marker in hen.patrol_points:
			route.append(marker.position)
		plan.routes.append(route)
	return plan


func _activate(plan: Plan) -> void:
	for wall in _walls.get_children():
		wall.free()
	for area in plan.walls:
		var wall: StaticBody2D = WALL_SCENE.instantiate()
		wall.position = area.get_center()
		if area.size.y > area.size.x:
			wall.rotation = PI * 0.5
		_walls.add_child(wall)
	_player.position = plan.player
	_farmer.position = plan.farmer
	for index in range(_crates.size()):
		_crates[index].position = plan.crates[index]
	for index in range(_nests.size()):
		_nests[index].position = plan.nests[index]
	for index in range(_supplies.size()):
		_supplies[index].position = plan.supplies[index]
	for index in range(_hens.size()):
		var hen: CoopChicken = _hens[index]
		hen.position = plan.hen_spawns[index]
		for marker_index in range(hen.patrol_points.size()):
			hen.patrol_points[marker_index].position = plan.routes[index][marker_index]

	var map := _region.get_world_2d().navigation_map
	var region_id := _region.get_rid()
	_previous_map_iteration = NavigationServer2D.map_get_iteration_id(map)
	_previous_region_iteration = NavigationServer2D.region_get_iteration_id(region_id)
	var mesh := NavigationPolygon.new()
	mesh.agent_radius = 16.0
	mesh.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.parsed_collision_mask = 2
	var source := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(mesh, source, _level)
	source.add_traversable_outline(_floor.transform * _floor.polygon)
	NavigationServer2D.bake_from_source_geometry_data(mesh, source)
	_region.navigation_polygon = mesh
	_frames_left = 120
	set_physics_process(true)


func _opening_is_safe() -> bool:
	for hen: CoopChicken in _hens:
		var offset := _player.global_position - hen.global_position
		if offset.is_zero_approx():
			return false
		if offset.length() > hen.vision_distance:
			continue
		var heading := Vector2.RIGHT
		if not hen.patrol_points.is_empty():
			var first_step := hen.patrol_points[0].global_position - hen.global_position
			if not first_step.is_zero_approx():
				heading = first_step
		if absf(heading.angle_to(offset)) <= deg_to_rad(hen.vision_angle * 0.5):
			var ray := PhysicsRayQueryParameters2D.create(hen.global_position, _player.global_position, hen.collision_mask)
			if hen.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				return false
	return true


func _verify_navigation(map: RID) -> bool:
	var targets := PackedVector2Array([_exit.global_position, _farmer.global_position])
	for target: Node2D in _nests + _supplies:
		targets.append(target.global_position)
	for hen: CoopChicken in _hens:
		targets.append(hen.global_position)
		var from := hen.global_position
		for marker in hen.patrol_points:
			var path := NavigationServer2D.map_get_path(map, from, marker.global_position, true)
			if path.is_empty() or path[-1].distance_to(marker.global_position) > 1.0:
				return false
			from = marker.global_position
	for point in targets:
		var path := NavigationServer2D.map_get_path(map, _player.global_position, point, true)
		if path.is_empty() or path[0].distance_to(_player.global_position) > 1.0 or path[-1].distance_to(point) > 1.0:
			return false
	return true
