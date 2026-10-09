shader_type canvas_item;

// GIZ: deixa a arte do jogo com cara de "desenho a giz no quadro-negro" (tutoriais).
// Contorno claro em volta do desenho + granulado de giz + cor um pouco mais clara.
// Respeita o modulate do nó (cor e transparência).

uniform vec4 chalk_color : source_color = vec4(0.96, 0.94, 0.88, 1.0);
// Largura do contorno de giz, em pixels da arte.
uniform float outline_px : hint_range(0.0, 3.0, 0.5) = 1.0;
// Quanto o granulado "come" o desenho (0 = arte limpa).
uniform float grain : hint_range(0.0, 1.0) = 0.45;
// Clareia e dessatura a cor (0 = cor original).
uniform float pastel : hint_range(0.0, 1.0) = 0.18;

varying vec4 node_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	node_color = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	float n = hash(px);
	float n2 = hash(px + vec2(13.7, 5.3));
	vec4 result = vec4(0.0);
	if (c.a > 0.4) {
		float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		vec3 col = mix(c.rgb, vec3(l) * 0.5 + vec3(0.5), pastel);
		// Pontinhos de pó de giz por cima.
		col = mix(col, chalk_color.rgb, step(1.0 - grain * 0.08, n) * 0.4);
		float a = c.a * (1.0 - grain * 0.3 * step(0.9, n2));
		result = vec4(col, a);
	} else if (outline_px > 0.0) {
		float edge = 0.0;
		for (int i = 0; i < 8; i++) {
			float ang = 6.2831853 * float(i) / 8.0;
			vec2 off = vec2(cos(ang), sin(ang)) * outline_px * TEXTURE_PIXEL_SIZE;
			edge = max(edge, texture(TEXTURE, UV + off).a);
		}
		if (edge > 0.4) {
			result = vec4(chalk_color.rgb, chalk_color.a * (0.55 + 0.45 * n) * step(0.12, n2));
		}
	}
	COLOR = result * node_color;
}
