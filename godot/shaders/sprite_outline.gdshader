shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.35, 0.92, 1.0, 0.85);
uniform float outline_size : hint_range(0.0, 4.0) = 1.35;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE * outline_size;
	float a = c.a;
	float max_a = a;
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	if (a < alpha_threshold && max_a > alpha_threshold) {
		COLOR = outline_color;
		COLOR.a *= smoothstep(alpha_threshold, alpha_threshold + 0.25, max_a);
	} else {
		COLOR = c;
	}
}
