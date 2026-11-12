class_name ArcadeHen
extends Node2D

var world: ArcadeWorld
var golden := false
var target := Vector2.ZERO
var facing := Vector2.RIGHT
var wait := 0.0
var lay_left := 6.0
var art: CoopCharacterArt
signal egg_laid(point: Vector2, gold: bool)

func _ready() -> void:
	art = CoopCharacterArt.new()
	art.character = 2
	art.sprite_height = 43.0 if golden else 36.0
	if golden: art.modulate = Color(1.25,1.05,0.38)
	add_child(art)
	target = position
	lay_left = 1.0 if golden else world.rng.randf_range(4,8)

func _process(delta: float) -> void:
	wait = maxf(0,wait-delta)
	lay_left -= delta
	if lay_left <= 0.0:
		egg_laid.emit(position + Vector2(0,12),golden)
		lay_left = world.rng.randf_range(1.5,2.5) if golden else world.rng.randf_range(6,10)
	var moving := false
	if wait <= 0.0:
		if position.distance_to(target) < 3 or not world.step_clear(position,target):
			target = _nearby_target()
			wait = world.rng.randf_range(0.4,1.2)
		elif target != Vector2.INF:
			var offset := target-position
			facing = Vector2.from_angle(rotate_toward(facing.angle(),offset.angle(),delta*3.5))
			position += offset.limit_length(delta*(75.0 if golden else 45.0))
			moving = true
	art.update_pose(facing,moving,&"idle" if moving else &"eat",delta)
	queue_redraw()

func _draw() -> void:
	if golden:
		draw_arc(Vector2(0,-15),24,0,TAU,24,Color(1,0.8,0.2,0.45),2)
		draw_rect(Rect2(-4,-53,8,4),Color("ffe28a"))

func _nearby_target() -> Vector2:
	for attempt in range(20):
		var point := position + Vector2(world.rng.randf_range(-140,140),world.rng.randf_range(-140,140))
		if world.is_free(point,20,true) and world.step_clear(position,point): return point
	return position
