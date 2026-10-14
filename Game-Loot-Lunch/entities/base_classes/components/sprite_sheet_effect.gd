extends AnimatedSprite2D
class_name SpriteSheetEffect
## Efeito visual tirado de UMA linha de uma spritesheet em grade (brilho, fumaça, estrela...).
## Fica escondido e aparece só quando alguém chama `play_once()`.
##
## Para trocar o efeito basta mudar no Inspector:
##   - `sheet`: a imagem da spritesheet
##   - `row`: a linha (1 = primeira linha, 2 = segunda...)


signal effect_finished


const ANIMATION_NAME: StringName = &"efeito"


@export var sheet: Texture2D
## Linha da spritesheet, contando a partir de 1.
@export_range(1, 64) var row: int = 1
## Quantos quadros existem na linha.
@export_range(1, 128) var columns: int = 12
## Tamanho de cada quadro em pixels.
@export var frame_size: Vector2i = Vector2i(64, 64)
@export var fps: float = 20.0
@export var hide_when_finished: bool = true


func _ready() -> void:
	_build_frames()
	visible = not hide_when_finished
	animation_finished.connect(_on_animation_finished)


## Toca o efeito uma vez do começo.
func play_once() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(ANIMATION_NAME):
		return
	visible = true
	play(ANIMATION_NAME)
	frame = 0


func _build_frames() -> void:
	if sheet == null:
		push_warning("SpriteSheetEffect '%s': nenhuma spritesheet definida." % name)
		return

	var total_rows: int = int(sheet.get_height() / float(frame_size.y))
	if row > total_rows:
		push_warning("SpriteSheetEffect '%s': a imagem só tem %d linhas (row = %d)." % [name, total_rows, row])
		return

	var frames := SpriteFrames.new()
	frames.add_animation(ANIMATION_NAME)
	frames.set_animation_loop(ANIMATION_NAME, false)
	frames.set_animation_speed(ANIMATION_NAME, fps)

	for column in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			column * frame_size.x,
			(row - 1) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		frames.add_frame(ANIMATION_NAME, atlas)

	sprite_frames = frames
	animation = ANIMATION_NAME


func _on_animation_finished() -> void:
	if hide_when_finished:
		visible = false
	effect_finished.emit()
