shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.5) = 0.55;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.2;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.12;
uniform vec4 glow_tint : source_color = vec4(0.55, 0.95, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed + UV.x * 6.0);
	float mask = smoothstep(0.28, 0.88, lum);
	c.rgb *= 1.0 + glow_strength * mask * pulse;
	c.rgb = mix(c.rgb, c.rgb * glow_tint.rgb, mask * 0.35);
	COLOR = c;
}
