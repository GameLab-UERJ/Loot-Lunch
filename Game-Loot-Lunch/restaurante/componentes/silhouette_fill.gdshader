shader_type canvas_item;

// Pinta a arte de UMA cor só, mantendo a transparência dela.
// Usado pelo SpriteOutline: desenha cópias da arte deslocadas, atrás do sprite,
// e o que sobra para fora vira a silhueta.

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);
}
