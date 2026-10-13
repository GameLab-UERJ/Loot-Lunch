extends Resource
class_name SheetAnimation
## UMA ANIMAÇÃO tirada de uma spritesheet em tira (quadros do mesmo tamanho, lado a lado).
## É DADO (.tres): quem precisa de um efeito visual recebe um SheetAnimation no inspetor
## e não precisa saber de onde veio a arte.
##
## Usos: símbolo de status em cima do personagem (choque, confuso), efeito que toca uma
## vez (grande choque, rastro da esfera), personagem virando pó...
##
##     var sprite := anim.create_sprite()          # AnimatedSprite2D pronto, já tocando
##     SheetAnimation.spawn_once(anim, fase, pos)  # toca uma vez no mundo e some
##
## Novo: FileSystem > botão direito > New Resource > SheetAnimation.


const ANIMATION_NAME: StringName = &"default"


@export var texture: Texture2D
## Tamanho de cada quadro, em pixels.
@export var frame_size: Vector2i = Vector2i(64, 64)
## Linha da spritesheet (1 = primeira).
@export_range(1, 64) var row: int = 1
## Primeira coluna (1 = primeira).
@export_range(1, 128) var first_column: int = 1
## Quantos quadros. 0 = todos até o fim da linha.
@export_range(0, 128) var frame_count: int = 0
@export var fps: float = 12.0
@export var loop: bool = true

@export_group("Posição")
## Deslocamento do desenho em relação a quem usa (ex.: (0, -20) = em cima da cabeça).
@export var offset: Vector2 = Vector2.ZERO
## Desenha na frente (positivo) ou atrás (negativo) de quem usa.
@export var z_index: int = 10
@export var scale: Vector2 = Vector2.ONE


## Quantos quadros a animação tem de fato.
func get_frame_count() -> int:
	if frame_count > 0:
		return frame_count
	if texture == null or frame_size.x <= 0:
		return 0
	return maxi(int(texture.get_width() / frame_size.x) - (first_column - 1), 0)


## Duração de uma volta, em segundos.
func get_duration() -> float:
	return get_frame_count() / maxf(fps, 0.001)


## Adiciona esta animação num SpriteFrames (com o nome `animation`).
func add_to(frames: SpriteFrames, animation: StringName = ANIMATION_NAME) -> void:
	if frames.has_animation(animation):
		frames.remove_animation(animation)
	frames.add_animation(animation)
	frames.set_animation_loop(animation, loop)
	frames.set_animation_speed(animation, fps)
	if texture == null:
		return
	for i in get_frame_count():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			(first_column - 1 + i) * frame_size.x,
			(row - 1) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		frames.add_frame(animation, atlas)


func build_frames(animation: StringName = ANIMATION_NAME) -> SpriteFrames:
	var frames := SpriteFrames.new()
	add_to(frames, animation)
	return frames


## AnimatedSprite2D já configurado (posição, camada, escala) e tocando.
func create_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = build_frames()
	sprite.position = offset
	sprite.z_index = z_index
	sprite.scale = scale
	sprite.play(ANIMATION_NAME)
	return sprite


## Toca a animação UMA vez em `parent` (na posição global `at`) e apaga no fim.
## Com `follow` o efeito vira filho de `follow` (anda junto com ele).
static func spawn_once(anim: SheetAnimation, parent: Node, at: Vector2,
		follow: Node2D = null) -> AnimatedSprite2D:
	if anim == null or anim.texture == null:
		return null
	var host: Node = follow if follow != null else parent
	if host == null or not is_instance_valid(host):
		return null
	var sprite: AnimatedSprite2D = anim.create_sprite()
	sprite.sprite_frames.set_animation_loop(ANIMATION_NAME, false)
	host.add_child(sprite)
	if follow == null:
		sprite.global_position = at + anim.offset
	sprite.animation_finished.connect(sprite.queue_free)
	return sprite
