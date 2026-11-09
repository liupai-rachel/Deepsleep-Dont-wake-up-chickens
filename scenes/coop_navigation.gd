class_name CoopNavigation
extends RefCounted


static func next_offset(body: CharacterBody2D, target: Vector2, require_exact_target := false) -> Vector2:
	var offset := target - body.global_position
	if offset.length_squared() <= 1.0:
		return Vector2.ZERO
	if not body.test_move(body.global_transform, offset):
		return offset

	var map := body.get_world_2d().navigation_map
	var path := NavigationServer2D.map_get_path(map, body.global_position, target, true)
	if path.is_empty() or (require_exact_target and path[-1].distance_squared_to(target) > 1.0):
		return Vector2.INF
	for point in path:
		var to_point := point - body.global_position
		if to_point.length_squared() > 1.0:
			return to_point
	return Vector2.ZERO
