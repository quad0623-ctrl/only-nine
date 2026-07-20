shader_type canvas_item;

/// Fullscreen overlay (no screen sample) — vignette + grain + soft cyan wash
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.78;
uniform float vignette_softness : hint_range(0.2, 1.2) = 0.48;
uniform float grain_amount : hint_range(0.0, 0.15) = 0.04;
uniform float scanline_amount : hint_range(0.0, 0.2) = 0.05;
uniform vec4 wash : source_color = vec4(0.04, 0.14, 0.2, 0.08);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float dist = length((uv - vec2(0.5)) * vec2(1.2, 1.05));
	float vig = smoothstep(vignette_softness, 1.15, dist) * vignette_strength;
	float scan = sin(uv.y * 980.0 + TIME * 1.6) * 0.5 + 0.5;
	float n = hash(uv * vec2(1400.0, 900.0) + vec2(TIME * 18.0, TIME * 3.0));
	float a = clamp(vig * 0.88 + scan * scanline_amount * 0.35 + n * grain_amount, 0.0, 0.92);
	vec3 col = mix(vec3(0.0), wash.rgb, wash.a + vig * 0.25);
	COLOR = vec4(col, a);
}
