extends Node2D
class_name SinkHole
## BURACO que ENGOLE coisas para baixo (buraco do inferno da Mandy, areia movediça,
## bueiro...). Abre no chão, as coisas afundam cortadas pela borda do buraco e ele fecha.
##
##   await buraco.open()                 # animação "abrir" -> fica em loop
##   buraco.add_ghost(sprite_do_chef)    # uma CÓPIA do sprite afunda (o original some)
##   await buraco.sink()                 # as cópias descem `sink_depth` px
##   await buraco.close()                # "fechar" e some
##
## O corte é feito com uma MÁSCARA (imagem): branco = aparece, preto = escondido.
## Ela precisa ter o mesmo tamanho dos quadros do buraco e ficar alinhada com eles.
##
## Estrutura da cena:
##   Buraco (Node2D, este script)
##   ├── Tras        AnimatedSprite2D: abrir / loop / fechar (fundo do buraco, fogo...)
##   ├── Mascara     Sprite2D (a textura vem de `mask_texture`, recorta os filhos)
##   │   └── Afundando  Node2D: as cópias que afundam ficam aqui
##   └── Frente      AnimatedSprite2D: loop (a borda da frente, por cima de quem afunda)


signal opened
signal sunk
signal closed


@export_group("Máscara")
## Imagem da máscara (branco = visível). Pode ser em tons de cinza, sem transparência.
@export var mask_texture: Texture2D

@export_group("Afundar")
## Quantos pixels as coisas descem.
@export var sink_depth: float = 44.0
## Segundos afundando.
@export var sink_time: float = 1.2
## Tremidinha para os lados enquanto afunda (pixels). 0 = sem.
@export var sink_shake: float = 1.0

@export_group("Animações")
@export var open_animation: StringName = &"abrir"
@export var loop_animation: StringName = &"loop"
@export var close_animation: StringName = &"fechar"


var is_open: bool = false


@onready var back: AnimatedSprite2D = $Tras
@onready var mask: Sprite2D = $Mascara
@onready var sinking: Node2D = $Mascara/Afundando
@onready var front: AnimatedSprite2D = get_node_or_null("Frente")


func _ready() -> void:
	mask.texture = _build_mask(mask_texture)
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	if front:
		front.visible = false


## Abre o buraco (toca "abrir" e fica no loop).
func open() -> void:
	if back and _has(back, open_animation):
		back.play(open_animation)
		await back.animation_finished
	if not is_inside_tree():
		return
	is_open = true
	if back and _has(back, loop_animation):
		back.play(loop_animation)
	if front and _has(front, loop_animation):
		front.visible = true
		front.play(loop_animation)
	opened.emit()


## Põe uma CÓPIA de `source` (AnimatedSprite2D ou Sprite2D) no buraco, no mesmo lugar da
## tela, e esconde o original. Retorna a cópia.
func add_ghost(source: CanvasItem, animation: StringName = &"") -> Node2D:
	if source == null or not is_instance_valid(source):
		return null
	var ghost: Node2D = null
	if source is AnimatedSprite2D:
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = source.sprite_frames
		animated.animation = animation if animation != &"" else source.animation
		animated.frame = source.frame
		animated.flip_h = source.flip_h
		animated.flip_v = source.flip_v
		animated.offset = source.offset
		animated.centered = source.centered
		animated.play(animated.animation)
		ghost = animated
	elif source is Sprite2D:
		var sprite := Sprite2D.new()
		sprite.texture = source.texture
		sprite.region_enabled = source.region_enabled
		sprite.region_rect = source.region_rect
		sprite.hframes = source.hframes
		sprite.vframes = source.vframes
		sprite.frame = source.frame
		sprite.flip_h = source.flip_h
		sprite.offset = source.offset
		sprite.centered = source.centered
		ghost = sprite
	else:
		return null
	ghost.self_modulate = source.self_modulate
	sinking.add_child(ghost)
	ghost.global_position = (source as Node2D).global_position
	ghost.global_scale = (source as Node2D).global_scale
	source.visible = false
	return ghost


## Afunda tudo que estiver no buraco.
func sink() -> void:
	var start: Vector2 = sinking.position
	var tween: Tween = create_tween()
	tween.tween_method(func(t: float) -> void:
		var shake: float = sin(t * 40.0) * sink_shake * (1.0 - t)
		sinking.position = start + Vector2(shake, sink_depth * t * t),
		0.0, 1.0, sink_time)
	await tween.finished
	sunk.emit()


## Fecha e some.
func close() -> void:
	is_open = false
	if front:
		front.visible = false
	sinking.visible = false
	if back and _has(back, close_animation):
		back.play(close_animation)
		await back.animation_finished
	closed.emit()
	queue_free()


## A máscara pode vir em tons de cinza sem transparência: vira "branco com alfa = brilho",
## que é o que o recorte (clip_children) usa.
static func _build_mask(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return texture
	image = image.duplicate()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1, 1, 1, pixel.r * pixel.a))
	return ImageTexture.create_from_image(image)


func _has(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	return sprite.sprite_frames != null and animation != &"" \
		and sprite.sprite_frames.has_animation(animation)
