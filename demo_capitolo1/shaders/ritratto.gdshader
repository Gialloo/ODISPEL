shader_type canvas_item;
// Ritratto «da adesivo»: contorno pieno del colore del personaggio più un filo nero.
// Con duotono = 1 diventa a due colori col retino nei mezzitoni (vignette e trittico).
uniform vec4 contorno : source_color = vec4(1.0);
uniform float spessore = 9.0;
uniform float duotono = 0.0;
uniform vec4 scuro : source_color = vec4(0.04, 0.0, 0.02, 1.0);
uniform vec4 chiaro : source_color = vec4(1.0, 0.14, 0.25, 1.0);
uniform float cella = 8.0;
varying vec2 locale;
varying vec4 tinta;   // il modulate: nel fragment COLOR è già moltiplicato per la texture

void vertex() {
	locale = VERTEX;
	tinta = COLOR;
}

void fragment() {
	vec4 m = tinta;
	vec4 t = texture(TEXTURE, UV);
	// textureSize e non TEXTURE_PIXEL_SIZE: col renderer di compatibilità questo vale zero sui TextureRect
	float vicino = 0.0;
	float lontano = 0.0;
	if (spessore > 0.0) {
		for (int i = 0; i < 16; i++) {
			float a = 6.2831853 * float(i) / 16.0;
			vec2 o = vec2(cos(a), sin(a)) / vec2(textureSize(TEXTURE, 0));
			vicino = max(vicino, texture(TEXTURE, UV + o * spessore).a);
			lontano = max(lontano, texture(TEXTURE, UV + o * (spessore + 5.0)).a);
		}
	}
	vec3 c = t.rgb;
	if (duotono > 0.5) {
		float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
		mat2 rot = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071));
		vec2 f = fract(rot * locale / cella) - 0.5;
		float punto = 1.0 - smoothstep(0.26, 0.33, length(f));
		float liv = l < 0.2 ? 0.0 : (l < 0.48 ? punto : 1.0);
		c = mix(scuro.rgb, chiaro.rgb, liv);
		c = mix(c, vec3(1.0), smoothstep(0.78, 0.95, l) * 0.85);
	}
	vec3 bordo = mix(vec3(0.0), contorno.rgb, step(0.5, vicino));
	float a_bordo = max(vicino, lontano);
	vec3 rgb = mix(bordo, c, t.a);
	float a = max(t.a, a_bordo);
	COLOR = vec4(rgb * m.rgb, a * m.a);
}
