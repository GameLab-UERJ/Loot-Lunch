shader_type canvas_item;

// Pinta a arte de UMA cor só. Só os pixels sólidos (alpha >= 0.9) entram: brilhos e
// auras semitransparentes da arte não viram silhueta.
// Usado pelo SpriteOutline: desenha cópias da arte deslocadas, atrás do sprite,
// e o que sobra para fora vira a silhueta.

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR = vec4(tint.rgb, step(0.9, texture(TEXTURE, UV).a) * tint.a);
}
