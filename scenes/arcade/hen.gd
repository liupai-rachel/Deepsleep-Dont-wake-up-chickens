class_name ArcadeHen
extends CoopChicken

var world: ArcadeWorld
var golden := false
var lay_left := 6.0
signal egg_laid(point: Vector2, gold: bool)

func _ready() -> void:
	if golden:
		_body.modulate = Color(1.25,1.05,0.38)
		_body.scale = Vector2.ONE * 1.15
	lay_left = 1.0 if golden else world.rng.randf_range(4,8)

func _physics_process(delta: float) -> void:
	# Reuse the original patrol, turning, occluded vision cone and alarm logic.
	if NavigationServer2D.map_get_iteration_id(get_world_2d().navigation_map) == 0: return
	super._physics_process(delta)
	lay_left -= delta
	if lay_left <= 0.0:
		egg_laid.emit(position + Vector2(0,12),golden)
		lay_left = world.rng.randf_range(1.5,2.5) if golden else world.rng.randf_range(6,10)
	queue_redraw()

func _draw() -> void:
	if golden:
		draw_arc(Vector2(0,-15),24,0,TAU,24,Color(1,0.8,0.2,0.45),2)
		draw_rect(Rect2(-4,-53,8,4),Color("ffe28a"))
