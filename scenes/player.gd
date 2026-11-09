class_name CoopPlayer
extends CharacterBody2D

@export_range(1.0, 600.0, 1.0) var move_speed := 250.0

var movement_locked := false
var searching := false
var _facing := Vector2.UP
var _motion_phase := 0.0

@onready var _art: Node2D = $Art
@onready var _search_glow: Sprite2D = $SearchGlow


func aim_direction() -> Vector2:
	var direction := Vector2.ZERO if movement_locked else _move_input()
	return _facing if direction.is_zero_approx() else direction.normalized()


func _physics_process(delta: float) -> void:
	_motion_phase += delta
	_search_glow.visible = searching
	if movement_locked:
		velocity = Vector2.ZERO
		_art.position.y = sin(_motion_phase * 18.0) * 1.4 if searching else 0.0
		return
	var direction := _move_input()
	if not direction.is_zero_approx():
		_facing = direction.normalized()
		_art.rotation = Vector2.UP.angle_to(_facing)
	velocity = direction * move_speed
	move_and_slide()
	_art.position.y = sin(_motion_phase * 22.0) * 1.8 if get_real_velocity().length_squared() > 1.0 else 0.0


func _move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
