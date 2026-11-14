class_name ArcadeNest
extends Node2D

const STRAW := preload("res://assets/art/open_straw_nest.png")
const NEST_REGION := Rect2(223,225,1074,582)
var stock := 0
var refill_left := 0.0
var refill_speed := 1.0
var rng := RandomNumberGenerator.new()
var tray: Node2D
var badge: Label
var theme_index := 0
var plant_growth: Array[float] = []
var highlighted := false:
	set(value):
		highlighted = value
		modulate = Color(1.14,1.1,1.03) if value else Color.WHITE

func _ready() -> void:
	if theme_index == 3:
		var soil := Node2D.new()
		soil.draw.connect(_draw_garden)
		add_child(soil)
		tray = Node2D.new()
		tray.draw.connect(_draw_stock)
		tray.material = ThemeSprites.item_material(theme_index)
		tray.z_index = 1
		add_child(tray)
		var front := Node2D.new()
		front.z_index = 2
		front.draw.connect(_draw_garden_front.bind(front))
		add_child(front)
	else:
		var texture := AtlasTexture.new()
		texture.atlas = STRAW
		texture.region = NEST_REGION
		var factor := 110.0 / NEST_REGION.size.x
		var art := Sprite2D.new()
		art.texture = texture
		art.scale = Vector2.ONE * factor
		art.position.y = 10.0 - NEST_REGION.size.y * factor * 0.5
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var cutout := ShaderMaterial.new()
		cutout.shader = preload("res://assets/art/pixel_cutout.gdshader")
		art.material = cutout
		add_child(art)
		tray = Node2D.new()
		tray.draw.connect(_draw_stock)
		tray.z_index = 1
		add_child(tray)
		# The lower straw lip is drawn again in front of the eggs for real occlusion.
		var front := Sprite2D.new()
		front.texture = texture
		front.scale = art.scale
		front.position = art.position
		front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		front.z_index = 2
		var foreground := ShaderMaterial.new()
		foreground.shader = preload("res://assets/art/nest_front.gdshader")
		foreground.set_shader_parameter("front_start",(NEST_REGION.position.y+NEST_REGION.size.y*0.61)/STRAW.get_height())
		front.material = foreground
		add_child(front)
	badge = Label.new()
	badge.position = Vector2(-28, 14)
	badge.size = Vector2(56,20)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_override("font", preload("res://assets/fonts/CoopUI.ttf"))
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color("ffe4a4"))
	badge.add_theme_color_override("font_outline_color", Color("172033"))
	badge.add_theme_constant_override("outline_size", 4)
	add_child(badge)
	if theme_index > 0: tray.material = ThemeSprites.item_material(theme_index)
	refill()

func refill() -> void:
	stock = rng.randi_range(2,6)
	if theme_index == 3:
		plant_growth.clear()
		for i in range(6): plant_growth.append(-i*0.06)
	refill_left = 0.0
	if is_instance_valid(tray): tray.queue_redraw()

func take() -> bool:
	if stock <= 0: return false
	stock -= 1
	if stock == 0: refill_left = rng.randf_range(4.0,7.0) * refill_speed
	tray.queue_redraw()
	return true

func _process(delta: float) -> void:
	if theme_index == 3:
		for i in range(plant_growth.size()): plant_growth[i] = minf(1.0,plant_growth[i]+delta/0.6)
		tray.queue_redraw()
	if refill_left > 0.0:
		refill_left = maxf(0.0, refill_left - delta)
		if refill_left == 0.0: refill()
	badge.text = "%ds" % ceili(refill_left) if stock == 0 else ""

func _draw_stock() -> void:
	if theme_index == 3:
		for i in range(mini(stock,6)):
			var point := Vector2((i%3-1)*31,-31+(i/3)*25)
			var growth := clampf(plant_growth[i] if i < plant_growth.size() else 1.0,0.0,1.0)
			ArcadeEgg.paint_resource(tray,point+Vector2(0,7*(1.0-growth)),maxf(0.12,growth),false,theme_index)
			if growth < 1:
				for side in [-1,1]: tray.draw_rect(Rect2(point+Vector2(side*(5+growth*8),6-sin(growth*PI)*7),Vector2(2,2)),Color("ac7542"))
		return
	var back_count := stock if stock <= 3 else ceili(stock/2.0)
	var front_count := 0 if stock <= 3 else stock-back_count
	for row in range(2):
		var count := back_count if row == 0 else front_count
		for i in range(count):
			var x := (float(i)-float(count-1)*0.5)*19.0
			var y := -23.0 if stock <= 3 else (-29.0 if row == 0 else -18.0)
			ArcadeEgg.paint_resource(tray,Vector2(x,y),0.85,false,theme_index)

func _draw_garden() -> void:
	var soil := get_child(0) as Node2D
	soil.draw_rect(Rect2(-56,-51,112,72),Color("402c25"))
	soil.draw_rect(Rect2(-52,-47,104,64),Color("765032"))
	for row in range(3):
		soil.draw_rect(Rect2(-47,-42+row*21,94,3),Color("553923"))
		soil.draw_rect(Rect2(-45,-38+row*21,90,2),Color("93623a"))
	for i in range(12):
		soil.draw_rect(Rect2(-43+(i*29)%85,-43+(i*17)%53,3,2),Color("b17d48"))
	for y in [-50,-39]: soil.draw_rect(Rect2(-57,y,114,4),Color("9b683c"))
	for x in [-57,53]:
		soil.draw_rect(Rect2(x,-52,4,70),Color("6e482d"))
		soil.draw_rect(Rect2(x,-52,2,70),Color("bc8853"))
	for x in [-59,-22,18,53]: _fence_post(soil,Vector2(x,-58))

func _fence_post(canvas: Node2D, point: Vector2) -> void:
	canvas.draw_rect(Rect2(point,Vector2(7,21)),Color("3b2e29"))
	canvas.draw_rect(Rect2(point+Vector2(1,1),Vector2(5,17)),Color("ac7947"))
	canvas.draw_rect(Rect2(point+Vector2(1,1),Vector2(2,16)),Color("d1a367"))
	canvas.draw_rect(Rect2(point+Vector2(2,5),Vector2(2,2)),Color("544339"))

func _draw_garden_front(canvas: Node2D) -> void:
	# A small gate keeps the plot readable without adding new collision rules.
	for x in [-57,14]:
		for y in [10,20]:
			canvas.draw_rect(Rect2(x,y,43,5),Color("453023"))
			canvas.draw_rect(Rect2(x,y,42,3),Color("c18b50"))
	for x in [-59,-19,13,53]: _fence_post(canvas,Vector2(x,3))
