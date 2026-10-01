extends AnimatedSprite2D
class_name SheetRowSprite
## Animação em LOOP tirada de uma spritesheet em grade, UMA linha por vez.
## Cada linha da imagem vira uma animação ("linha_1", "linha_2"...), e quem usa
## só escolhe a linha com `show_row()`.
##
## Reutilizável: espetinho girando na churrasqueira (9 linhas = 3 espetinhos x 3 pontos),
## panela borbulhando, item brilhando na bancada...
##
## Ao trocar de linha o quadro atual é mantido, então a troca cru -> no ponto
## não "pula" a rotação do espetinho.


@export var sheet: Texture2D
## Tamanho de cada quadro em pixels.
@export var frame_size: Vector2i = Vector2i(16, 16)
@export var fps: float = 10.0


var _row: int = 0


func _ready() -> void:
	_build_frames()
	visible = false


## Mostra e toca a linha pedida (contando a partir de 1). 0 ou menos esconde.
func show_row(row: int) -> void:
	if row <= 0 or sprite_frames == null or not sprite_frames.has_animation(_animation_for(row)):
		hide_row()
		return
	visible = true
	if row == _row and is_playing():
		return
	var current_frame: int = frame
	var progress: float = frame_progress
	_row = row
	play(_animation_for(row))
	set_frame_and_progress(current_frame % sprite_frames.get_frame_count(animation), progress)


func hide_row() -> void:
	_row = 0
	visible = false
	stop()


func get_row() -> int:
	return _row


func get_row_count() -> int:
	if sheet == null or frame_size.y <= 0:
		return 0
	return int(sheet.get_height() / float(frame_size.y))


func _animation_for(row: int) -> StringName:
	return StringName("linha_%d" % row)


func _build_frames() -> void:
	if sheet == null:
		push_warning("SheetRowSprite '%s': nenhuma spritesheet definida." % name)
		return

	var columns: int = int(sheet.get_width() / float(frame_size.x))
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in range(1, get_row_count() + 1):
		var animation_name: StringName = _animation_for(row)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, fps)
		for column in columns:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(
				column * frame_size.x,
				(row - 1) * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			frames.add_frame(animation_name, atlas)
	sprite_frames = frames
	if frames.has_animation(_animation_for(1)):
		animation = _animation_for(1)
