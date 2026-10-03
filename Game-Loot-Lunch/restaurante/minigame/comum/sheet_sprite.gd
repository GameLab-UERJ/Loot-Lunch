extends AnimatedSprite2D
class_name SheetSprite
## AnimatedSprite2D montado a partir de SheetAnimation (.tres) do restaurante, sem
## precisar desenhar SpriteFrames à mão no editor. Cada SheetAnimation vira uma animação
## com o nome do `resource_name` dela (vazio = "anim_1", "anim_2"...).
##
##   sprite.play_sheet(&"andar")                    # troca de animação
##   await sprite.play_once(&"risada")              # toca uma vez e espera o fim
##   await sprite.wait_frame(&"frigideirada", 4)    # espera o quadro do golpe
##
## Quadros de tamanhos diferentes na mesma sprite (ex.: chef 32x32 parado e 48x48
## dando frigideirada): o `offset` de cada SheetAnimation (em pixels da arte) é aplicado
## quando a animação começa, para o personagem não "pular" de lugar. Com `flip_h` o
## deslocamento em X é espelhado sozinho (chame `refresh_offset()` depois de virar).
##
## Reutilizável: chef idle das etapas, Mini-Sol, formigas da batalha, churrasqueira...


## Lista de SheetAnimation (.tres). Array[Resource] de propósito: mesmo motivo das listas
## de receitas do restaurante (o Inspector aceita arrastar o .tres sem brigar com o tipo).
@export var sheets: Array[Resource] = []
## Animação que toca ao entrar na cena. Vazio = a primeira da lista.
@export var start_animation: StringName = &""


## Deslocamento (pixels da arte) de cada animação.
var _offsets: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for i in sheets.size():
		var sheet := sheets[i] as SheetAnimation
		if sheet == null:
			continue
		var anim_name: StringName = name_of(sheet, i)
		sheet.add_to(frames, anim_name)
		_offsets[anim_name] = sheet.offset
	sprite_frames = frames
	animation_changed.connect(refresh_offset)
	var first: StringName = start_animation
	if first == &"" and not sheets.is_empty():
		first = name_of(sheets[0] as SheetAnimation, 0)
	if first != &"" and frames.has_animation(first):
		play(first)
	refresh_offset()


static func name_of(sheet: SheetAnimation, index: int) -> StringName:
	if sheet != null and sheet.resource_name != "":
		return StringName(sheet.resource_name)
	return StringName("anim_%d" % (index + 1))


func has_sheet(anim_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim_name)


## Toca a animação pelo nome (ignora se não existir). Retorna se trocou.
func play_sheet(anim_name: StringName, restart: bool = false) -> bool:
	if not has_sheet(anim_name):
		return false
	if animation == anim_name and is_playing() and not restart:
		return true
	play(anim_name)
	if restart:
		frame = 0
	refresh_offset()
	return true


## Toca uma vez (animação sem loop) e espera acabar. Uso: `await sprite.play_once(&"risada")`.
func play_once(anim_name: StringName) -> void:
	if not play_sheet(anim_name, true):
		return
	if sprite_frames.get_animation_loop(anim_name):
		await get_tree().create_timer(sprite_frames.get_frame_count(anim_name) \
			/ maxf(sprite_frames.get_animation_speed(anim_name), 0.001), false).timeout
	else:
		await animation_finished


## Espera a animação `anim_name` chegar no quadro `target_frame` (0 = primeiro).
## Volta na hora se outra animação assumir no meio (ninguém fica preso no `await`).
func wait_frame(anim_name: StringName, target_frame: int) -> void:
	if not has_sheet(anim_name):
		return
	target_frame = mini(target_frame, sprite_frames.get_frame_count(anim_name) - 1)
	while is_inside_tree() and animation == anim_name and is_playing() and frame < target_frame:
		await frame_changed
		if animation != anim_name:
			return


## Aplica o deslocamento da animação atual (espelhado se `flip_h`).
func refresh_offset() -> void:
	var base: Vector2 = _offsets.get(animation, Vector2.ZERO)
	offset = Vector2(-base.x if flip_h else base.x, base.y)
