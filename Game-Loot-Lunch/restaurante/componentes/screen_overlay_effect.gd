extends CanvasLayer
class_name ScreenOverlayEffect
## Animação que aparece NO MEIO DA TELA do jogador, por cima de tudo (quack gigante do
## Patolino, susto, aviso de "desorientado"...). Não é do mundo: não anda com a câmera.
##
## Toca as colunas de UMA linha de uma spritesheet:
##   1. "entrada": todos os quadros uma vez;
##   2. "segura": repete os últimos `hold_frames` quadros por `hold_time` segundos;
##   3. some com fade (`fade_time`) e se apaga sozinha.
## No quadro `peak_frame` emite `peak_reached` -> é a hora do efeito (ex.: derrubar o item).
## Enquanto está na tela pode tremer (`shake_strength`), e treme a Camera2D ativa também.
##
## Não precisa de cena:
##     var fx := ScreenOverlayEffect.new()
##     fx.sheet = minha_textura; fx.frame_size = Vector2i(256, 256); fx.opacity = 0.5
##     fx.peak_reached.connect(...)
##     get_tree().current_scene.add_child(fx)


signal peak_reached
signal finished


@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(256, 256)
## Linha da spritesheet, contando a partir de 1.
@export_range(1, 64) var row: int = 1
## Quantos quadros tem a linha. 0 = calcula pela largura da imagem.
@export_range(0, 128) var frame_count: int = 0
@export var fps: float = 8.0
## 0 = invisível, 1 = opaco. 0.5 = meio transparente (dá para ver o jogo por trás).
@export_range(0.0, 1.0) var opacity: float = 0.5
## Tamanho na tela. 1 = tamanho original da arte.
@export var overlay_scale: float = 1.0
## Quadro (contando de 1) em que o efeito "acontece".
@export_range(1, 128) var peak_frame: int = 1
## Quantos quadros finais ficam repetindo enquanto segura.
@export_range(1, 128) var hold_frames: int = 2
@export var hold_time: float = 0.5
@export var fade_time: float = 0.3
## Tremida em pixels (0 = parado).
@export var shake_strength: float = 3.0
## Treme também a Camera2D ativa (se a fase tiver uma).
@export var shake_camera: bool = true


var _sprite: AnimatedSprite2D
var _peak_sent: bool = false
var _shaking: bool = false
var _camera: Camera2D = null
var _camera_offset: Vector2 = Vector2.ZERO
var _base_position: Vector2 = Vector2.ZERO


func _init() -> void:
	layer = 50


func _ready() -> void:
	if sheet == null:
		push_warning("ScreenOverlayEffect sem spritesheet.")
		_emit_peak()
		_end()
		return

	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2.ONE * overlay_scale
	_sprite.modulate.a = opacity
	add_child(_sprite)

	_base_position = get_viewport().get_visible_rect().size * 0.5
	_sprite.position = _base_position

	if shake_camera:
		_camera = get_viewport().get_camera_2d()
		if _camera:
			_camera_offset = _camera.offset

	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_intro_finished)
	_shaking = shake_strength > 0.0
	_sprite.play(&"entrada")
	_on_frame_changed()


func _process(_delta: float) -> void:
	if not _shaking or _sprite == null:
		return
	var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
	jitter = jitter.round()
	_sprite.position = _base_position + jitter
	if is_instance_valid(_camera):
		_camera.offset = _camera_offset + jitter


func _exit_tree() -> void:
	_stop_shake()


func _build_frames() -> SpriteFrames:
	var total: int = frame_count if frame_count > 0 else int(sheet.get_width() / float(frame_size.x))
	total = maxi(total, 1)
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"entrada")
	frames.set_animation_loop(&"entrada", false)
	frames.set_animation_speed(&"entrada", fps)

	frames.add_animation(&"segura")
	frames.set_animation_loop(&"segura", true)
	frames.set_animation_speed(&"segura", fps)

	var first_hold: int = maxi(total - hold_frames, 0)
	for column in total:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(column * frame_size.x, (row - 1) * frame_size.y, frame_size.x, frame_size.y)
		frames.add_frame(&"entrada", atlas)
		if column >= first_hold:
			frames.add_frame(&"segura", atlas)
	return frames


func _on_frame_changed() -> void:
	if _sprite.animation == &"entrada" and _sprite.frame >= peak_frame - 1:
		_emit_peak()


func _on_intro_finished() -> void:
	if _sprite.animation != &"entrada":
		return
	_emit_peak()
	_sprite.play(&"segura")
	await get_tree().create_timer(hold_time, false).timeout
	if not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_end)


func _emit_peak() -> void:
	if _peak_sent:
		return
	_peak_sent = true
	peak_reached.emit()


func _stop_shake() -> void:
	_shaking = false
	if is_instance_valid(_camera):
		_camera.offset = _camera_offset


func _end() -> void:
	_stop_shake()
	finished.emit()
	queue_free()
