class_name ThemeSprites
extends RefCounted

const ATLAS := preload("res://assets/art/harvest_animals.png")
const ANIMALS := [
	[Rect2(54,85,260,216),Rect2(374,85,260,216),Rect2(692,85,260,216),Rect2(1007,85,260,216)],
	[Rect2(49,402,260,184),Rect2(369,402,260,184),Rect2(688,402,260,184),Rect2(1010,402,260,184)],
	[Rect2(43,689,270,201),Rect2(372,689,270,201),Rect2(693,689,270,201),Rect2(1004,689,270,201)],
]
const ITEMS := [Rect2(1396,138,128,120),Rect2(1406,427,111,122),Rect2(1390,736,141,121)]
static var _items: Array[AtlasTexture] = []

static func item(kind: int) -> AtlasTexture:
	if _items.is_empty():
		for region in ITEMS:
			var texture := AtlasTexture.new()
			texture.atlas = ATLAS
			texture.region = region
			_items.append(texture)
	return _items[kind-1]
