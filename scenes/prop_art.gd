extends Sprite2D

const ATLAS := preload("res://assets/art/coop_props.png")
const REGIONS := [Rect2(190, 80, 400, 410), Rect2(735, 80, 735, 410), Rect2(190, 560, 380, 395), Rect2(900, 650, 435, 240)]
@export_enum("Nest", "Cover", "Feed sack", "Grain") var prop := 0
@export var display_size := Vector2(70, 82)
@export var ground_offset := 20.0

func _ready() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = ATLAS
	atlas.region = REGIONS[prop]
	texture = atlas
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = display_size / atlas.region.size
	position.y = ground_offset - display_size.y * 0.5
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/art/pixel_cutout.gdshader")
	material = cutout
