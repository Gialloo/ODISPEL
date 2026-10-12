shader_type canvas_item;

// Retino da fumetto: puntini che si ingrossano verso i bordi e il basso dello schermo.
// Disegna solo nero con trasparenza; va sopra lo schermo senza leggerlo.

uniform float dot_size : hint_range(4.0, 20.0) = 9.0;
uniform float strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 ink : source_color = vec4(0.0, 0.03, 0.05, 1.0);

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = UV * res;
	// reticolo inclinato a 45 gradi come nei retini veri
	vec2 r = vec2(p.x + p.y, p.x - p.y) * 0.7071;
	vec2 cell = fract(r / dot_size) - 0.5;
	float d = length(cell);
	// quanto "inchiostro": cresce dai bordi e dal basso
	vec2 c = UV - 0.5;
	float edge = clamp(dot(c, c) * 2.2 + max(UV.y - 0.55, 0.0) * 0.9, 0.0, 1.0);
	float radius = edge * 0.62;
	float a = step(d, radius) * strength * edge;
	COLOR = vec4(ink.rgb, a);
}
