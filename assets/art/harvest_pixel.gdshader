shader_type canvas_item;
uniform vec4 frame_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 pixel_grid = vec2(36.0, 28.0);
uniform vec2 atlas_size = vec2(1619.0, 971.0);
varying vec4 node_tint;
void vertex() { node_tint = COLOR; }
void fragment() {
 // Leave text, shadows and solid-color drawing commands untouched.
 if (abs(TEXTURE_PIXEL_SIZE.x - 1.0 / atlas_size.x) < 0.000001 && abs(TEXTURE_PIXEL_SIZE.y - 1.0 / atlas_size.y) < 0.000001) {
  vec2 local_uv = clamp((UV-frame_region.xy)/frame_region.zw, vec2(0.0), vec2(0.99999));
  vec2 cell = (floor(local_uv*pixel_grid)+vec2(0.5))/pixel_grid;
  vec4 texel = texture(TEXTURE, frame_region.xy+cell*frame_region.zw);
  if (texel.a < 0.6) discard;
  COLOR = vec4(floor(texel.rgb*15.0+0.5)/15.0, 1.0)*node_tint;
 }
}
