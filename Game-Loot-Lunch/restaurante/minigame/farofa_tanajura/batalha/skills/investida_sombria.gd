extends BattleSkill
## 2. INVESTIDA SOMBRIA: o chef deixa a SOMBRA no lugar (sombra_chef), some numa
## fumaça, dispara para cima da formiga deixando rastros (afterimages), dá a trombada e
## volta INSTANTANEAMENTE para a sombra (outra fumaça).


@export var damage: int = 10
@export var dash_time: float = 0.14
@export var dash_tint: Color = Color(0.55, 0.45, 0.8, 0.85)
@export var approach_offset: Vector2 = Vector2(-52, 24)
## Rastros deixados no caminho.
@export_range(0, 8) var trail_count: int = 4

@export_group("Arte")
@export var shadow_anim: SheetAnimation
@export var smoke_anim: SheetAnimation
@export var trail_anim: SheetAnimation
@export var impact: SheetAnimation


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	var origin: Vector2 = user.global_position
	var flip: bool = user.sprite.flip_h if user.sprite else false
	user.face(target.global_position)

	# 1. Sombra no lugar + fumaça.
	var shadow: AnimatedSprite2D = null
	if shadow_anim:
		shadow = shadow_anim.create_sprite()
		shadow.flip_h = flip
		battle.add_effect(shadow)
		shadow.global_position = origin
	battle.fx(smoke_anim, origin)

	# 2. Dash com rastros.
	var to: Vector2 = target.global_position + approach_offset
	if user.sprite:
		user.sprite.modulate = dash_tint
	for i in trail_count:
		_leave_trail(battle, user, origin.lerp(to, float(i + 1) / float(trail_count + 1)), i * dash_time / maxf(trail_count, 1))
	await user.move_to(to, dash_time, Tween.TRANS_EXPO)
	var direction: Vector2 = target.global_position - user.global_position
	target.take_hit(damage, direction)
	battle.fx(impact, target.global_position + Vector2(-30, 0))
	battle.shake(4.0, 0.2)
	await user.squash(Vector2(0.75, 1.25), 0.12)

	# 3. Volta para a sombra (teleporte).
	battle.fx(smoke_anim, user.global_position)
	user.global_position = origin
	if user.sprite:
		user.sprite.modulate = Color.WHITE
	battle.fx(smoke_anim, origin)
	if is_instance_valid(shadow):
		var fade := shadow.create_tween()
		fade.tween_property(shadow, "modulate:a", 0.0, 0.2)
		fade.tween_callback(shadow.queue_free)
	await user.squash(Vector2(0.7, 1.3), 0.15)
	user.face(target.global_position)


func _leave_trail(battle: TurnBattle, user: ChefBattler, at: Vector2, delay: float) -> void:
	if trail_anim == null:
		return
	await battle.wait(delay)
	var trail: AnimatedSprite2D = battle.fx(trail_anim, at)
	if trail and user.sprite:
		trail.flip_h = user.sprite.flip_h
