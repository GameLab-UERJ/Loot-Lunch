shader_type canvas_item;

// Aura (contorno brilhante) em volta de uma arte com transparência.
// Desenha SÓ a parte de fora do desenho: coloque este sprite ATRÁS do sprite normal.
//
// A COR vem do modulate / self_modulate do nó (e não de um uniform), assim cada
// instância tem sua cor sem precisar duplicar o material.

// Largura da aura, em pixels da textura.
uniform float thickness : hint_range(1.0, 8.0, 0.5) = 3.0;
// 0 = aura sólida até a borda; 1 = vai sumindo para fora.
uniform float softness : hint_range(0.0, 1.0) = 0.55;
// Velocidade e força da "pulsação".
uniform float pulse_speed = 4.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.45;

varying vec4 node_color;

void vertex() {
	// Aqui COLOR = cor do vértice x modulate x self_modulate.
	node_color = COLOR;
}

void fragment() {
	float inside = texture(TEXTURE, UV).a;
	float glow = 0.0;
	int steps = int(ceil(thickness));

	for (int r = 1; r <= steps; r++) {
		float falloff = 1.0 - softness * (float(r - 1) / max(thickness, 1.0));
		for (int i = 0; i < 12; i++) {
			float angle = 6.2831853 * float(i) / 12.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * float(r) * TEXTURE_PIXEL_SIZE;
			glow = max(glow, texture(TEXTURE, UV + offset).a * falloff);
		}
	}

	glow *= 1.0 - inside;
	float pulse = 1.0 - pulse_amount * (0.5 + 0.5 * sin(TIME * pulse_speed));
	COLOR = vec4(node_color.rgb, node_color.a * glow * pulse);
}
