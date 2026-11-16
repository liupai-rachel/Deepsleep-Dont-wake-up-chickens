extends CoopCharacterArt

var theme_index := 1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for region in ThemeSprites.ANIMALS[theme_index-1]:
		var texture := AtlasTexture.new()
		texture.atlas = ThemeSprites.ATLAS
		texture.region = region
		_frames.append(texture)
	_sprite = Sprite2D.new()
	_sprite.texture = _frames[0]
	_pixel_scale = 42.0/_frames[0].region.size.y
	_sprite.scale = Vector2.ONE*_pixel_scale
	_sprite.position.y = -21
	_sprite.material = ThemeSprites.pixel_material(_frames[0].region)
	add_child(_sprite)

func update_pose(direction: Vector2, moving: bool, action: StringName, delta: float) -> void:
	if _sprite == null: return
	_phase += delta
	var index := 0
	if moving: index = [1,0,2,0][floori(_phase*10.0)%4]
	if action == &"alarm": index = 3
	_sprite.texture = _frames[index]
	var region: Rect2 = _frames[index].region
	_sprite.material.set_shader_parameter("frame_region",Vector4(region.position.x/ThemeSprites.ATLAS.get_width(),region.position.y/ThemeSprites.ATLAS.get_height(),region.size.x/ThemeSprites.ATLAS.get_width(),region.size.y/ThemeSprites.ATLAS.get_height()))
	_sprite.flip_h = direction.x < -0.05
	_sprite.position.y = -21.0-absf(sin(_phase*12.0))*0.8 if moving else -21.0
