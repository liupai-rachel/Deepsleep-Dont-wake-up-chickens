class_name FarmScenery
extends StaticBody2D

const ATLAS := preload("res://assets/art/farm_nature.png")
const REGIONS := [Rect2(27,34,467,476),Rect2(584,46,362,463),Rect2(1048,270,445,237),Rect2(148,775,213,181),Rect2(622,765,259,192),Rect2(1043,683,453,274)]
var kind := 0
var display_width := 120.0
var footprint := Vector2.ZERO
var art: Sprite2D

func _ready() -> void:
	collision_layer = 2 if footprint != Vector2.ZERO else 0
	collision_mask = 0
	if footprint != Vector2.ZERO:
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = footprint
		collider.shape = shape
		collider.add_to_group("vision_cover")
		add_child(collider)
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = REGIONS[kind]
	art = Sprite2D.new()
	art.texture = texture
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.scale = Vector2.ONE*display_width/texture.region.size.x
	art.position.y = (footprint.y*0.5 if footprint != Vector2.ZERO else 4)-texture.region.size.y*art.scale.y*0.5
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/art/foliage_cutout.gdshader")
	art.material = cutout
	add_child(art)
	set_process(kind <= 1)

func _process(delta: float) -> void:
	var world := get_parent() as ArcadeWorld
	if world == null or not is_instance_valid(world.actor): return
	var offset := world.actor.position-position
	var behind: bool = offset.y < 10 and offset.y > -REGIONS[kind].size.y*art.scale.y and absf(offset.x) < display_width*0.48
	art.modulate.a = move_toward(art.modulate.a,0.38 if behind else 1.0,delta*5)
