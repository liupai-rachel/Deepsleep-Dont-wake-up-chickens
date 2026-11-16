class_name FarmProps
extends RefCounted

const ATLAS := preload("res://assets/art/farm_theme_props.png")
const REGIONS := [Rect2(48,159,354,232),Rect2(504,32,322,380),Rect2(926,122,352,271),Rect2(1360,160,378,229),Rect2(26,597,393,176),Rect2(485,562,360,232),Rect2(916,599,366,189),Rect2(1359,596,379,194)]
static var _textures: Array[AtlasTexture] = []

static func texture(index: int) -> AtlasTexture:
	if _textures.is_empty():
		for region in REGIONS:
			var item := AtlasTexture.new()
			item.atlas = ATLAS
			item.region = region
			_textures.append(item)
	return _textures[index]

static func sprite(index: int, width: float, ground_offset := 0.0) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(index)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var factor: float = width/REGIONS[index].size.x
	result.scale = Vector2.ONE*factor
	result.position.y = ground_offset-REGIONS[index].size.y*factor*0.5
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/art/pixel_cutout.gdshader")
	result.material = cutout
	return result
