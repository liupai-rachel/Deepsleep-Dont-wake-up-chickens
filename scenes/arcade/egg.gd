class_name ArcadeEgg
extends Node2D

var golden := false
var has_snake := false
var growth_age := 0.0
var claimed := false
var phase := 0.0
var highlighted := false
var theme_index := 0

static func paint_resource(canvas: CanvasItem, center: Vector2, factor: float, gold: bool, kind: int, lit := false) -> void:
	if kind == 0:
		paint(canvas,center,factor,gold,lit)
		return
	var texture := ThemeSprites.item(kind)
	var size := texture.region.size*(19.0*factor/texture.region.size.y)
	var tint := Color(1.5,1.25,0.5) if gold else Color.WHITE
	if lit:
		tint *= Color(1.2,1.15,1.0)
		canvas.draw_rect(Rect2(center+Vector2(-11,-10)*factor,Vector2(3,3)*factor),Color("fff0a8"))
	canvas.draw_texture_rect(texture,Rect2(center-size*0.5,size),false,tint)

static func paint(canvas: CanvasItem, center: Vector2, factor: float, gold: bool, lit := false) -> void:
	var outline := Color("fff0a8") if lit else Color("342333")
	var shell := Color("ffd04c") if gold else Color("f6dbad")
	var shade := Color("ce801f") if gold else Color("c59872")
	var light := Color("fff4a6") if gold else Color("fff7dc")
	var points := PackedVector2Array([Vector2(-3,-10),Vector2(2,-10),Vector2(5,-7),Vector2(7,-2),Vector2(7,4),Vector2(4,8),Vector2(-4,8),Vector2(-7,4),Vector2(-7,-2),Vector2(-5,-7)])
	for i in range(points.size()): points[i] = center + points[i] * factor
	canvas.draw_colored_polygon(points, outline)
	canvas.draw_rect(Rect2(center + Vector2(-4,-6)*factor, Vector2(8,12)*factor), shell)
	canvas.draw_rect(Rect2(center + Vector2(-2,-8)*factor, Vector2(4,3)*factor), shell)
	canvas.draw_rect(Rect2(center + Vector2(-5,-2)*factor, Vector2(10,6)*factor), shell)
	canvas.draw_rect(Rect2(center + Vector2(2,0)*factor, Vector2(3,6)*factor), shade)
	canvas.draw_rect(Rect2(center + Vector2(-3,-5)*factor, Vector2(3,5)*factor), light)
	canvas.draw_rect(Rect2(center + Vector2(-2,6)*factor, Vector2(5,1)*factor), shade)

func _ready() -> void:
	if theme_index > 0: material = ThemeSprites.item_material(theme_index)

func _process(delta: float) -> void:
	growth_age += delta
	phase += delta
	queue_redraw()

func _draw() -> void:
	var bob := sin(phase * 3.0) * 1.2 if theme_index != 3 else 0.0
	draw_rect(Rect2(-6, 6, 12, 3), Color(0.12,0.08,0.1,0.3))
	if golden:
		for i in range(3):
			var p := Vector2.from_angle(phase + i * TAU / 3) * 12
			draw_rect(Rect2(p - Vector2.ONE, Vector2(2,2)), Color("ffe78b"))
	if theme_index == 3:
		draw_rect(Rect2(-10,5,20,4),Color("563721"))
		var growth := clampf(growth_age/0.65,0.0,1.0)
		if growth < 1.0:
			for i in range(4):
				var p := Vector2((i-1.5)*(5.0+growth*7.0),4.0-sin(growth*PI)*9.0)
				draw_rect(Rect2(p,Vector2(2,2)),Color("a46a38"))
		paint_resource(self,Vector2(0,6.0*(1.0-growth)),maxf(0.12,growth),golden,theme_index,highlighted)
	else: paint_resource(self,Vector2(0,bob),1.0,golden,theme_index,highlighted)
