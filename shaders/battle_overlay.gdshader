shader_type canvas_item;

// Il velo delle schermate in UN solo passaggio (battaglia e menu): velatura ciano, effetto
// telecamera (linee di scansione, vignettatura, rumore, banda) e retino da fumetto.
// Prima erano tre rettangoli a tutto schermo sovrapposti (cctv_overlay + halftone +
// velatura): stesso aspetto, un terzo del lavoro per la scheda video.

uniform vec4 tint = vec4(0.1, 0.6, 0.7, 0.08);
uniform float scan_strength : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.62;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.07;
uniform float dot_size : hint_range(4.0, 20.0) = 9.0;
uniform float halftone_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 ink : source_color = vec4(0.0, 0.03, 0.05, 1.0);
uniform bool dots_on_top = true;   // true: retino sopra la telecamera (battaglia); false: sotto (menu)

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Sovrapposizione di colori PREMOLTIPLICATI (top sopra bottom): niente divisioni, niente rami.
vec4 over_pm(vec4 top, vec4 bottom) {
	return top + bottom * (1.0 - top.a);
}

void fragment() {
	vec2 uv = UV;

	// telecamera (come cctv_overlay)
	float a = (0.5 + 0.5 * sin(uv.y * 2261.95)) * scan_strength;
	vec2 c0 = uv - vec2(0.5);
	float cc = dot(c0, c0);
	a += smoothstep(0.35, 0.95, length(c0 * vec2(1.0, 1.15))) * vignette_strength;
	a += hash(floor(uv * vec2(640.0, 360.0)) + floor(TIME * 24.0)) * noise_strength;
	float band = fract(TIME * 0.07);
	float bright = smoothstep(0.05, 0.0, abs(uv.y - band)) * 0.07;
	float cam_a = clamp(a, 0.0, 0.92) * (1.0 - bright * 4.0);
	vec4 cam = vec4(vec3(bright * 6.0) * cam_a, cam_a);

	// retino (come halftone): il punto c'e' dove la distanza dal centro della cella e' minore del raggio;
	// si confrontano i quadrati, cosi' non serve la radice
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = uv * res;
	vec2 r = vec2(p.x + p.y, p.x - p.y) * 0.7071;
	vec2 cell = fract(r / dot_size) - 0.5;
	float edge = clamp(cc * 2.2 + max(uv.y - 0.55, 0.0) * 0.9, 0.0, 1.0);
	float rad = edge * 0.62;
	float ht_a = step(dot(cell, cell), rad * rad) * halftone_strength * edge;
	vec4 dots = vec4(ink.rgb * ht_a, ht_a);

	vec4 base = vec4(tint.rgb * tint.a, tint.a);
	vec4 res_pm = dots_on_top ? over_pm(dots, over_pm(cam, base)) : over_pm(cam, over_pm(dots, base));
	COLOR = res_pm.a > 0.0001 ? vec4(res_pm.rgb / res_pm.a, res_pm.a) : vec4(0.0);
}
