shader_type canvas_item;

// Sovrapposizione "telecamera di sorveglianza": linee di scansione, vignettatura,
// rumore leggero e una banda di disturbo che scende lentamente.
// Non legge lo schermo: disegna solo nero con trasparenza.

uniform float scan_strength : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.62;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.07;

// Hash senza sin(): molto piu' economico sulle schede video deboli.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = UV;
	float scan = 0.5 + 0.5 * sin(uv.y * 2261.95);   // 720 * PI
	float a = scan * scan_strength;

	vec2 c = uv - vec2(0.5);
	float v = smoothstep(0.35, 0.95, length(c * vec2(1.0, 1.15)));
	a += v * vignette_strength;

	float n = hash(floor(uv * vec2(640.0, 360.0)) + floor(TIME * 24.0));
	a += n * noise_strength;

	float band = fract(TIME * 0.07);
	float d = abs(uv.y - band);
	vec3 col = vec3(0.0);
	float bright = smoothstep(0.05, 0.0, d) * 0.07;

	COLOR = vec4(col + vec3(bright * 6.0), clamp(a, 0.0, 0.92) * (1.0 - bright * 4.0));
}
