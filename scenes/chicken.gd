class_name CoopChicken
extends CharacterBody2D

signal player_visibility_changed(detected: bool)

const VISION_SEGMENTS := 32
const CORNER_OFFSET := 0.0001
const PATROL_CONE := Color(1.0, 0.79, 0.36, 0.23)
const DETECTED_CONE := Color(1.0, 0.29, 0.23, 0.36)
const PATROL_FEATHERS := Color(0.98, 0.91, 0.75)
const DETECTED_FEATHERS := Color(1.0, 0.47, 0.43)

@export var patrol_points: Array[Marker2D] = []
@export var player: CoopPlayer
@export_range(1.0, 250.0, 1.0) var patrol_speed := 64.0
@export_range(0.0, 5.0, 0.05) var waypoint_pause := 0.65
@export_range(0.0, 1.0, 0.05) var turn_back_chance := 0.3
@export_range(0.0, 3.0, 0.05) var pause_variation := 0.3
@export_range(0.0, 0.6, 0.05) var speed_variation := 0.2
@export_range(16.0, 600.0, 1.0) var vision_distance := 158.0
@export_range(10.0, 170.0, 1.0) var vision_angle := 78.0
@export_range(0.0, 600.0, 1.0) var hearing_distance := 210.0
@export_range(0.1, 10.0, 0.1) var cluck_cooldown := 2.0
@export_group("Feed")
@export_range(20.0, 500.0, 1.0) var bait_sense_distance := 235.0
@export_range(1.0, 250.0, 1.0) var bait_walk_speed := 100.0
@export_range(0.5, 10.0, 0.1) var eating_seconds := 2.5
@export_range(0.1, 1.0, 0.05) var eating_sense_scale := 0.5

var sees_player := false

var _facing := Vector2.RIGHT
var _waypoint_index := 0
var _patrol_direction := 1
var _segment_speed_offset := 0.0
var _wait_left := 0.0
var _cluck_cooldown_left := 0.0
var _bait: CoopFeed
var _eat_left := 0.0
var _returning_to_patrol := false
var _motion_phase := 0.0
var _vision_ray := PhysicsRayQueryParameters2D.new()
var _patrol_rng := RandomNumberGenerator.new()

@onready var _body: Node2D = $Body
@onready var _feathers: Polygon2D = $Body/Feathers
@onready var _vision: Polygon2D = $Vision
@onready var _notice: Label = $Notice
@onready var _pecking: Label = $Pecking


func set_patrol_seed(seed_value: int) -> void:
	_patrol_rng.seed = seed_value
	_segment_speed_offset = _patrol_rng.randf_range(-1.0, 1.0)


func _physics_process(delta: float) -> void:
	var previous_position := position
	_motion_phase += delta
	_cluck_cooldown_left = maxf(_cluck_cooldown_left - delta, 0.0)
	if not _follow_bait(delta):
		if _returning_to_patrol:
			_return_to_patrol(delta)
		else:
			_patrol(delta)
	_body.rotation = _facing.angle()
	_pecking.visible = _eat_left > 0.0
	if _pecking.visible:
		_body.position = _facing * (sin(_motion_phase * 23.0) * 2.2)
	else:
		_body.position.y = sin(_motion_phase * 18.0) * 1.5 if position != previous_position else 0.0
		_body.position.x = 0.0

	var space := get_world_2d().direct_space_state
	var half_angle := deg_to_rad(vision_angle * 0.5)
	var sight_range := vision_distance * _sense_scale()
	_vision_ray.collision_mask = collision_mask
	_vision_ray.from = global_position
	_update_vision(space, half_angle, sight_range)
	_set_player_visible(_can_see_player(space, half_angle, sight_range))


func hear_search_noise(origin: Vector2) -> bool:
	if _cluck_cooldown_left > 0.0:
		return false
	var hearing_range := hearing_distance * _sense_scale()
	if global_position.distance_squared_to(origin) > hearing_range * hearing_range:
		return false
	_cluck_cooldown_left = cluck_cooldown
	return true


func _sense_scale() -> float:
	return eating_sense_scale if _eat_left > 0.0 else 1.0


func _follow_bait(delta: float) -> bool:
	if not is_instance_valid(_bait) or _bait.is_queued_for_deletion():
		_bait = _find_bait()
		_eat_left = 0.0
		if _bait == null:
			return false
		_bait.claimed = true
		_returning_to_patrol = true

	if _eat_left > 0.0:
		_eat_left = maxf(0.0, _eat_left - delta)
		if is_zero_approx(_eat_left):
			_eat_left = 0.0
			_bait.queue_free()
			_bait = null
		return true

	if global_position.distance_squared_to(_bait.global_position) <= 81.0:
		_eat_left = eating_seconds
		return true

	var offset := CoopNavigation.next_offset(self, _bait.global_position, true)
	if offset == Vector2.INF:
		_bait.claimed = false
		_bait = null
		return false
	_move_toward_feed_point(offset, bait_walk_speed, delta)
	return true


func _find_bait() -> CoopFeed:
	var nearest: CoopFeed
	var nearest_distance := INF
	for bait: CoopFeed in get_tree().get_nodes_in_group("dropped_feed"):
		if bait.claimed or bait.is_queued_for_deletion():
			continue
		var distance := global_position.distance_squared_to(bait.global_position)
		if distance > bait_sense_distance * bait_sense_distance or distance >= nearest_distance:
			continue
		if CoopNavigation.next_offset(self, bait.global_position, true) != Vector2.INF:
			nearest = bait
			nearest_distance = distance
	return nearest


func _return_to_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_returning_to_patrol = false
		return
	var offset := CoopNavigation.next_offset(self, patrol_points[_waypoint_index].global_position)
	if offset == Vector2.INF or offset.is_zero_approx():
		_returning_to_patrol = false
		return
	_move_toward_feed_point(offset, patrol_speed, delta)


func _move_toward_feed_point(offset: Vector2, speed: float, delta: float) -> void:
	if not offset.is_zero_approx():
		_facing = offset.normalized()
		move_and_collide(offset.limit_length(speed * delta))


func _exit_tree() -> void:
	if is_instance_valid(_bait):
		_bait.claimed = false


func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	if _wait_left > 0.0:
		_wait_left -= delta
		return

	var offset := patrol_points[_waypoint_index].global_position - global_position
	var distance := offset.length()
	if distance > 0.0:
		_facing = offset / distance
		var speed := patrol_speed * (1.0 + _segment_speed_offset * speed_variation)
		var step := minf(speed * delta, distance)
		var collision := move_and_collide(_facing * step)
		if collision == null and step < distance:
			return

	if patrol_points.size() > 2 and _patrol_rng.randf() < turn_back_chance:
		_patrol_direction = -_patrol_direction
	_waypoint_index = posmod(_waypoint_index + _patrol_direction, patrol_points.size())
	_wait_left = maxf(0.0, waypoint_pause + _patrol_rng.randf_range(-pause_variation, pause_variation))
	_segment_speed_offset = _patrol_rng.randf_range(-1.0, 1.0)


func _can_see_player(space: PhysicsDirectSpaceState2D, half_angle: float, sight_range: float) -> bool:
	if not is_instance_valid(player):
		return false
	var offset := player.global_position - global_position
	if offset.length_squared() > sight_range * sight_range:
		return false
	if offset.is_zero_approx():
		return true
	if absf(_facing.angle_to(offset)) > half_angle:
		return false
	return _cast_vision_ray(space, player.global_position).is_empty()


func _update_vision(space: PhysicsDirectSpaceState2D, half_angle: float, sight_range: float) -> void:
	var angles := PackedFloat32Array()
	for segment in range(VISION_SEGMENTS + 1):
		angles.append(lerpf(-half_angle, half_angle, float(segment) / VISION_SEGMENTS))

	# Sample both sides of each cover corner so the fan follows its shadow edge.
	for cover: CollisionShape2D in get_tree().get_nodes_in_group("vision_cover"):
		var rectangle := cover.shape as RectangleShape2D
		if cover.disabled or rectangle == null:
			continue
		var half_size := rectangle.size * 0.5
		for corner in [
			-half_size,
			Vector2(half_size.x, -half_size.y),
			half_size,
			Vector2(-half_size.x, half_size.y),
		]:
			var angle := _facing.angle_to(cover.to_global(corner) - global_position)
			if absf(angle) < half_angle:
				angles.append(maxf(-half_angle, angle - CORNER_OFFSET))
				angles.append(angle)
				angles.append(minf(half_angle, angle + CORNER_OFFSET))

	angles.sort()
	var fan := PackedVector2Array([Vector2.ZERO])
	var previous_angle := -INF
	for angle in angles:
		if is_equal_approx(angle, previous_angle):
			continue
		previous_angle = angle
		var endpoint := global_position + _facing.rotated(angle) * sight_range
		var hit := _cast_vision_ray(space, endpoint)
		fan.append(to_local(hit.get("position", endpoint)))
	_vision.polygon = fan


func _cast_vision_ray(space: PhysicsDirectSpaceState2D, endpoint: Vector2) -> Dictionary:
	_vision_ray.to = endpoint
	return space.intersect_ray(_vision_ray)


func _set_player_visible(detected: bool) -> void:
	if detected == sees_player:
		return
	sees_player = detected
	_vision.color = DETECTED_CONE if detected else PATROL_CONE
	_feathers.color = DETECTED_FEATHERS if detected else PATROL_FEATHERS
	_notice.visible = detected
	player_visibility_changed.emit(detected)
