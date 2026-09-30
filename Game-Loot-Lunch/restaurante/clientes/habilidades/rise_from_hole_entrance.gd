extends SummonEntrance
class_name RiseFromHoleEntrance
## ENTRADA "SAI DO BURACO": abre um buraco no chão (SinkHole) e o summon SOBE de dentro
## dele, cortado pela borda, igual ao chef afundando na fusão dos demoninhos, só que ao
## contrário. Quando termina de subir, o summon de verdade assume dali e o buraco fecha.
##
## Mandy: o demoninho sai do buraco do inferno (buraco_invocacao.tscn). Os projéteis que
## ele solta ao sair (8 caveiras) são da SummonAbility (`burst_data`), não daqui.
##
## Enquanto sobe, o desenho é uma CÓPIA feita com o SpriteFrames do próprio summon
## (animação `rise_animation`), então qualquer summon serve, sem arte nova.


signal hole_opened
signal risen


@export_group("Buraco")
## Cena com SinkHole na raiz (ex.: buraco_inferno.tscn).
@export var hole_scene: PackedScene
## Onde o buraco abre, em relação a esta entrada.
@export var hole_offset: Vector2 = Vector2.ZERO
## Espera com o buraco aberto antes de começar a subir.
@export var wait_before_rise: float = 0.2
## Espera depois que o summon saiu, antes de fechar.
@export var close_delay: float = 0.4

@export_group("Subir")
## Animação do summon tocada enquanto sobe.
@export var rise_animation: StringName = &"voo"
## De quantos pixels abaixo ele começa a subir.
@export var rise_depth: float = 40.0
## Segundos subindo.
@export var rise_time: float = 0.9
## Sai olhando para o chef.
@export var face_target: bool = true


var hole: SinkHole = null


func _before_summon() -> void:
	if hole_scene == null:
		return
	hole = hole_scene.instantiate() as SinkHole
	if hole == null:
		push_error("RiseFromHoleEntrance: a cena do buraco não tem SinkHole na raiz.")
		return
	add_child(hole)
	hole.position = hole_offset
	hole.rise_depth = rise_depth
	hole.rise_time = rise_time

	await hole.open()
	if not is_inside_tree():
		return
	hole_opened.emit()
	if wait_before_rise > 0.0:
		await get_tree().create_timer(wait_before_rise, false).timeout
		if not is_inside_tree():
			return

	var source := _creature_sprite()
	if source:
		hole.add_ghost_frames(source.sprite_frames, rise_animation, get_summon_position(),
				_should_flip(), source.offset)
	await hole.rise()
	if not is_inside_tree():
		return
	risen.emit()
	hole.clear_ghosts()  # o summon de verdade aparece no mesmo lugar agora
	if source:
		source.flip_h = _should_flip()  # sai olhando para o mesmo lado da cópia


func _after_summon() -> void:
	if hole == null or not is_instance_valid(hole):
		return
	if close_delay > 0.0:
		await get_tree().create_timer(close_delay, false).timeout
		if not is_inside_tree() or not is_instance_valid(hole):
			return
	await hole.close()


func _creature_sprite() -> AnimatedSprite2D:
	if not is_instance_valid(creature):
		return null
	var sprite := creature.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return null
	return sprite


## Olha para o chef (a arte do summon olha para a direita ou esquerda?).
func _should_flip() -> bool:
	if not face_target or not is_instance_valid(target):
		return false
	var faces_right: bool = creature.get(&"sprite_faces_right") != false
	var to_the_left: bool = target.global_position.x < get_summon_position().x
	return to_the_left == faces_right
