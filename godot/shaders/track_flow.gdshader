shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(0.45, 0.95, 1.0, 0.85);
uniform vec4 edge_color : source_color = vec4(0.1, 0.45, 0.55, 0.35);
uniform float speed : hint_range(0.0, 6.0) = 1.8;
uniform float band_width : hint_range(0.05, 0.8) = 0.28;

void fragment() {
	float t = UV.x * 6.0 - TIME * speed;
	float band = smoothstep(0.0, band_width, abs(fract(t) - 0.5));
	float glow = 1.0 - band;
	float edge = smoothstep(0.0, 0.35, min(UV.y, 1.0 - UV.y));
	vec3 col = mix(edge_color.rgb, core_color.rgb, glow);
	float a = mix(edge_color.a, core_color.a, glow) * edge;
	COLOR = vec4(col, a) * COLOR;
}
