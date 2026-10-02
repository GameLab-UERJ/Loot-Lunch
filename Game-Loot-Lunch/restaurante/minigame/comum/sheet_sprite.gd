extends AnimatedSprite2D
class_name SheetSprite
## AnimatedSprite2D montado a partir de SheetAnimation (.tres) do restaurante, sem
## precisar desenhar SpriteFrames à mão no editor. Cada SheetAnimation vira uma animação
## com o nome do `resource_name` dela (vazio = "anim_1", "anim_2"...).
##
##   sprite.play_sheet(&"andar")   # troca de animação
##
## Reutilizável: chef idle das etapas, Mini-Sol, formigas da batalha, churrasqueira...


## Lista de SheetAnimation (.tres). Array[Resource] de propósito: mesmo motivo das listas
## de receitas do restaurante (o Inspector aceita arrastar o .tres sem brigar com o tipo).
@export var sheets: Array[Resource] = []
## Animação que toca ao entrar na cena. Vazio = a primeira da lista.
@export var start_animation: StringName = &""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for i in sheets.size():
		var sheet := sheets[i] as SheetAnimation
		if sheet == null:
			continue
		sheet.add_to(frames, name_of(sheet, i))
	sprite_frames = frames
	var first: StringName = start_animation
	if first == &"" and not sheets.is_empty():
		first = name_of(sheets[0] as SheetAnimation, 0)
	if first != &"" and frames.has_animation(first):
		play(first)


static func name_of(sheet: SheetAnimation, index: int) -> StringName:
	if sheet != null and sheet.resource_name != "":
		return StringName(sheet.resource_name)
	return StringName("anim_%d" % (index + 1))


## Toca a animação pelo nome (ignora se não existir). Retorna se trocou.
func play_sheet(anim_name: StringName, restart: bool = false) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(anim_name):
		return false
	if animation == anim_name and is_playing() and not restart:
		return true
	play(anim_name)
	if restart:
		frame = 0
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
