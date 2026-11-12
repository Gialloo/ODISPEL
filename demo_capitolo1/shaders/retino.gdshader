shader_type canvas_item;
// Retino da fumetto: punti ruotati di 45 gradi, che si rimpiccioliscono lungo una direzione.
uniform vec4 colore : source_color = vec4(1.0);
uniform vec4 fondo : source_color = vec4(0.0);
uniform float cella = 14.0;
uniform float r_max = 0.48;
uniform float r_min = 0.04;
uniform vec2 inizio = vec2(0.0);
uniform vec2 fine = vec2(600.0, 0.0);
varying vec2 locale;

void vertex() {
	locale = VERTEX;
}

void fragment() {
	vec4 m = COLOR;
	vec2 d = fine - inizio;
	float t = clamp(dot(locale - inizio, d) / max(dot(d, d), 1.0), 0.0, 1.0);
	float r = mix(r_max, r_min, t);
	mat2 rot = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071));
	vec2 f = fract(rot * locale / cella) - 0.5;
	float a = 1.0 - smoothstep(r - 0.05, r + 0.05, length(f));
	vec4 c = mix(fondo, colore, a);
	COLOR = vec4(c.rgb, c.a * m.a);
}
