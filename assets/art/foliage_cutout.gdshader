shader_type canvas_item;
varying vec4 item_tint;
void vertex() { item_tint = COLOR; }
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (pixel.a < 0.5) { discard; }
	COLOR = vec4(pixel.rgb * item_tint.rgb, item_tint.a);
}
