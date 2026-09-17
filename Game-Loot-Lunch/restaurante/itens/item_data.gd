extends Resource
class_name ItemData
## Dados de um item (tomate, cebola, prato...). Crie um .tres por item:
## Botão direito no FileSystem > New Resource > ItemData.


@export var id: StringName = &""
@export var display_name: String = ""
@export var texture: Texture2D
## Ajuste fino da posição do item quando está na mão / na bancada.
@export var hold_offset: Vector2 = Vector2.ZERO
## Escala do sprite (na mão, no chão e na bancada). Use < 1 para artes maiores que o personagem.
@export var sprite_scale: Vector2 = Vector2.ONE
## Cor do círculo desenhado quando não há textura (placeholder para testes).
@export var placeholder_color: Color = Color.WHITE
