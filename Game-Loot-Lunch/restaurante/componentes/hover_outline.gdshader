shader_type canvas_item;

// Silhueta (contorno) em volta de uma arte com transparência.
// Usado pelo InteractableComponent quando o mouse está em cima do objeto.
// Diferente da aura_outline, vai NO PRÓPRIO sprite: desenha a arte normal e o
// contorno por fora dela.

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Largura do contorno em pixels da TEXTURA (o componente já compensa a escala do nó).
uniform float width : hint_range(0.0, 16.0) = 1.0;

void fragment() {
	vec4 base = COLOR;
	float neighbor = 0.0;
	int steps = int(ceil(width));

	for (int r = 1; r <= steps; r++) {
		float dist = min(float(r), width);
		for (int i = 0; i < 8; i++) {
			float angle = 6.2831853 * float(i) / 8.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * dist * TEXTURE_PIXEL_SIZE;
			neighbor = max(neighbor, texture(TEXTURE, UV + offset).a);
		}
	}

	float outline_alpha = step(0.5, neighbor) * outline_color.a;
	float alpha = base.a + outline_alpha * (1.0 - base.a);
	vec3 rgb = base.rgb * base.a + outline_color.rgb * outline_alpha * (1.0 - base.a);
	COLOR = vec4(alpha > 0.0 ? rgb / alpha : vec3(0.0), alpha);
}
