extends Node2D

var radius := 140.0
var zoom := 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO,radius,Color(0.6,1.0,0.9,0.035))
	for i in range(48):
		var angle := float(i)*TAU/48
		draw_arc(Vector2.ZERO,radius,angle,angle+0.055,3,Color(0.65,1.0,0.9,0.55),1.1/zoom)
