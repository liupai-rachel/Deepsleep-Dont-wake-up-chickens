class_name CoopFeedField
extends Node2D

enum ThrowResult { PLACED, EMPTY, BLOCKED }

const FEED_SCENE := preload("res://scenes/feed.tscn")
const BAIT_SPACING_SQUARED := 324.0

@export_range(16.0, 80.0, 1.0) var pickup_distance := 38.0
@export_range(24.0, 160.0, 1.0) var throw_distance := 64.0

var held_count := 0

@onready var _supplies: Node2D = $Supplies
@onready var _baits: Node2D = $Baits


func nearest_pickup(origin: Vector2) -> CoopFeed:
	var nearest: CoopFeed
	var nearest_distance := INF
	for supply: CoopFeed in _supplies.get_children():
		if supply.is_queued_for_deletion():
			continue
		var distance := origin.distance_squared_to(supply.global_position)
		if distance <= pickup_distance * pickup_distance and distance < nearest_distance:
			nearest = supply
			nearest_distance = distance
	return nearest


func collect(supply: CoopFeed) -> void:
	if supply.is_queued_for_deletion():
		return
	supply.queue_free()
	held_count += 1


func throw_from(player: CoopPlayer) -> ThrowResult:
	if held_count == 0:
		return ThrowResult.EMPTY

	var offset := player.aim_direction() * throw_distance
	var destination := player.global_position + offset
	var map := get_world_2d().navigation_map
	if NavigationServer2D.map_get_iteration_id(map) == 0:
		return ThrowResult.BLOCKED
	if NavigationServer2D.map_get_closest_point(map, destination).distance_squared_to(destination) > 1.0:
		return ThrowResult.BLOCKED
	if player.test_move(player.global_transform, offset):
		return ThrowResult.BLOCKED
	for bait: CoopFeed in _baits.get_children():
		if not bait.is_queued_for_deletion() and bait.global_position.distance_squared_to(destination) < BAIT_SPACING_SQUARED:
			return ThrowResult.BLOCKED

	var bait: CoopFeed = FEED_SCENE.instantiate()
	bait.dropped = true
	bait.position = _baits.to_local(destination)
	_baits.add_child(bait)
	held_count -= 1
	return ThrowResult.PLACED
