extends BattleSkill
## 2. INVESTIDA SOMBRIA: o chef deixa uma SOMBRA no lugar (a mesma sombra.tscn da
## habilidade E do restaurante), dispara para cima da formiga numa trombada e
## volta INSTANTANEAMENTE para a sombra.


@export var damage: int = 10
## sombra.tscn (raiz com ChefShadow).
@export var shadow_scene: PackedScene
@export var dash_time: float = 0.16
@export var dash_tint: Color = Color(0.45, 0.35, 0.65, 0.75)
@export var approach_offset: Vector2 = Vector2(-22, 0)


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	var origin: Vector2 = user.global_position
	var shadow: ChefShadow = _leave_shadow(battle, user, origin)

	user.face(target.global_position)
	if user.sprite:
		user.sprite.modulate = dash_tint
	await user.move_to(target.global_position + approach_offset, dash_time, Tween.TRANS_EXPO)
	var direction: Vector2 = target.global_position - user.global_position
	target.take_hit(damage, direction)
	battle.shake(4.0, 0.2)
	await user.squash(Vector2(0.75, 1.25), 0.15)

	# Volta para a sombra (teleporte, igual à ShadowAbility).
	user.global_position = origin
	if user.sprite:
		user.sprite.modulate = Color.WHITE
	if is_instance_valid(shadow):
		shadow.vanish()
	await user.squash(Vector2(0.7, 1.3), 0.18)
	user.face(target.global_position)


func _leave_shadow(battle: TurnBattle, user: ChefBattler, at: Vector2) -> ChefShadow:
	if shadow_scene == null:
		return null
	var shadow := shadow_scene.instantiate() as ChefShadow
	if shadow == null:
		return null
	shadow.lifetime = 0.0  # quem some com ela é a habilidade
	shadow.source = user
	# A sombra tem o tamanho do chef do restaurante: um "suporte" com a escala do sprite.
	var holder := Node2D.new()
	holder.scale = user.sprite.scale if user.sprite else Vector2.ONE
	battle.add_effect(holder)
	holder.global_position = at
	holder.add_child(shadow)
	shadow.set_flip_h(user.sprite.flip_h if user.sprite else false)
	shadow.expired.connect(func() -> void:
		get_tree().create_timer(0.5).timeout.connect(holder.queue_free))
	return shadow
