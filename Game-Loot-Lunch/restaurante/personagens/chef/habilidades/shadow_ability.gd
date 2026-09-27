extends AbilityComponent
class_name ShadowAbility
## HABILIDADE 2 (tecla E): SOMBRA DE RETORNO.
##
##   1. Aperta E -> gasta 1 mana e deixa uma sombra nos pés do chef (virada para o
##      mesmo lado). Começa a contar a janela de retorno (`return_window`, 10 s).
##   2. Aperta E DE NOVO dentro da janela -> o chef VOLTA para onde a sombra está
##      (com o que estiver na mão) e a sombra some. Voltar não gasta mana.
##   3. Não apertou a tempo -> a sombra pisca no final e desaparece.
##
## Colocar como filho do Chef. A janela e o resto ficam no Inspector para calibrar.


signal shadow_placed(shadow: ChefShadow)
## O chef voltou para a sombra.
signal returned(from_position: Vector2, to_position: Vector2)
## A sombra sumiu sem ser usada (a janela acabou).
signal shadow_expired


## Cena da sombra (sombra.tscn).
@export var shadow_scene: PackedScene

@export_group("Retorno")
## Segundos que o jogador tem para apertar E de novo e voltar. Depois disso a sombra some.
@export_range(0.5, 60.0, 0.5, "suffix:s") var return_window: float = 10.0
## Desligado = E só deixa sombras (não volta).
@export var return_enabled: bool = true
## Nos últimos segundos da janela a sombra pisca, avisando que vai sumir.
@export_range(0.0, 10.0, 0.1, "suffix:s") var warning_time: float = 2.0
## Deixa um "rastro" (sombra que some rápido) no lugar de onde o chef saiu.
@export var leave_afterimage: bool = true

@export_group("Posição")
## Ajuste de posição da sombra em relação ao chef.
@export var spawn_offset: Vector2 = Vector2.ZERO


var _shadow: ChefShadow = null


func has_active_shadow() -> bool:
	return is_instance_valid(_shadow) and not _shadow.is_expiring()


func get_shadow() -> ChefShadow:
	return _shadow if has_active_shadow() else null


## Segundos que ainda faltam para poder voltar (0 = sem sombra).
func get_time_left() -> float:
	return _shadow.get_time_left() if has_active_shadow() else 0.0


func _on_press() -> bool:
	if not (user is Node2D):
		return false
	if has_active_shadow():
		if return_enabled:
			return _return_to_shadow()
		# Sem retorno: a sombra nova substitui a antiga.
		_shadow.expire()
	return _place_shadow()


func _place_shadow() -> bool:
	if shadow_scene == null:
		return false
	if not check_mana():
		return false
	var shadow := _spawn_shadow((user as Node2D).global_position + spawn_offset)
	if shadow == null:
		return false
	spend_mana()

	_shadow = shadow
	shadow.warning_time = warning_time
	shadow.start_lifetime(return_window)
	shadow.expired.connect(_on_shadow_expired.bind(shadow))

	activated.emit()
	shadow_placed.emit(shadow)
	return true


func _return_to_shadow() -> bool:
	var body := user as Node2D
	var from: Vector2 = body.global_position
	var to: Vector2 = _shadow.global_position - spawn_offset

	if leave_afterimage:
		var trail := _spawn_shadow(from)
		if trail:
			trail.vanish()

	body.global_position = to
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
	var shadow: ChefShadow = _shadow
	_shadow = null
	shadow.vanish()
	_pop_user_sprite()

	returned.emit(from, to)
	return true


func _spawn_shadow(at: Vector2) -> ChefShadow:
	var shadow := shadow_scene.instantiate() as ChefShadow
	if shadow == null:
		push_warning("ShadowAbility: shadow_scene precisa ter o script ChefShadow na raiz.")
		return null
	shadow.source = user
	_get_container().add_child(shadow)
	shadow.global_position = at
	shadow.set_flip_h(_get_user_flip())
	return shadow


func _on_shadow_expired(shadow: ChefShadow) -> void:
	if shadow == _shadow:
		_shadow = null
		shadow_expired.emit()


## "Pulinho" no sprite do chef ao chegar (feedback do teleporte).
func _pop_user_sprite() -> void:
	var sprite := user.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite == null:
		return
	sprite.scale = Vector2(0.7, 1.3)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _get_user_flip() -> bool:
	var sprite := user.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	return sprite.flip_h if sprite else false


func _get_container() -> Node:
	if user.has_method(&"_get_items_container"):
		return user.call(&"_get_items_container")
	return user.get_parent()
