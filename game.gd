extends Node2D

var player := Vector2(480, 270)
var target := Vector2(700, 220)
var score := 0
var speed := 250.0

func _process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    player += direction * speed * delta
    player.x = clampf(player.x, 20.0, 940.0)
    player.y = clampf(player.y, 20.0, 520.0)
    if player.distance_to(target) < 30.0:
        score += 1
        target = Vector2(randf_range(50.0, 910.0), randf_range(80.0, 490.0))
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        player = get_global_mouse_position()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 540), Color("152b35"))
    draw_circle(target, 16, Color("ffcf70"))
    draw_circle(player, 22, Color("7de0bf"))
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(30, 45), "CATCH THE LIGHT  /  %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
    draw_string(font, Vector2(30, 510), "Arrow keys to move  /  click or tap to jump", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
