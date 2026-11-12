class_name ArcadeNest
extends Node2D

const PROP := preload("res://scenes/prop_art.gd")
var stock := 0
var refill_left := 0.0
var refill_speed := 1.0
var rng := RandomNumberGenerator.new()
var tray: Node2D
var badge: Label

func _ready() -> void:
	var art := Sprite2D.new()
	art.set_script(PROP)
	art.display_width = 86.0
	art.ground_offset = 25.0
	add_child(art)
	tray = Node2D.new()
	tray.draw.connect(_draw_stock)
	tray.z_index = 1
	add_child(tray)
	badge = Label.new()
	badge.position = Vector2(-28, 28)
	badge.size = Vector2(56,20)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_override("font", preload("res://assets/fonts/CoopUI.ttf"))
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color("ffe4a4"))
	badge.add_theme_color_override("font_outline_color", Color("172033"))
	badge.add_theme_constant_override("outline_size", 4)
	add_child(badge)
	refill()

func refill() -> void:
	stock = rng.randi_range(2,6)
	refill_left = 0.0
	if is_instance_valid(tray): tray.queue_redraw()

func take() -> bool:
	if stock <= 0: return false
	stock -= 1
	if stock == 0: refill_left = rng.randf_range(4.0,7.0) * refill_speed
	tray.queue_redraw()
	return true

func _process(delta: float) -> void:
	if refill_left > 0.0:
		refill_left = maxf(0.0, refill_left - delta)
		if refill_left == 0.0: refill()
	badge.text = "%ds" % ceili(refill_left) if stock == 0 else ""

func _draw_stock() -> void:
	for i in range(stock):
		var x := -14.0 + float(i % 3) * 14.0
		var y := -13.0 + float(i / 3) * 12.0
		ArcadeEgg.paint(tray, Vector2(x,y), 0.55, false)
