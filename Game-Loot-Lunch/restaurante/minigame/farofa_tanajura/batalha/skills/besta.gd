extends BattleSkill
## 3. BESTA: tiro de virote à distância (substituiu o Bolo de Fogo). O chef saca a
## besta (`besta`, 7 quadros: 0 saca · 1-2 mira · 3 DISPARO · 4-5 recuo · 6 abaixa); no
## quadro do disparo o virote sai voando, acerta com faíscas e fica CRAVADO na formiga
## um tempinho. Muito dano, custa mana.


@export var damage: int = 13
@export var shoot_animation: StringName = &"besta"
@export var shoot_frame: int = 3
## Saída do virote em relação ao chef (no quadro 48x48: x ≈ 36, y = 34).
@export var muzzle_offset: Vector2 = Vector2(32, 4)
## Velocidade do virote (px/s).
@export var bolt_speed: float = 700.0
## Quanto tempo o virote fica cravado.
@export var stuck_time: float = 1.6
## O tiro também empurra a espera da formiga para trás.
@export_range(0.0, 1.0, 0.05) var wait_knock_back: float = 0.25

@export_group("Arte")
@export var bolt_anim: SheetAnimation
@export var impact: SheetAnimation
@export var stuck_texture: Texture2D


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.act(shoot_animation, shoot_frame)

	var side: float = -1.0 if (user.sprite and user.sprite.flip_h) else 1.0
	var from: Vector2 = user.global_position + Vector2(muzzle_offset.x * side, muzzle_offset.y)
	var hit_offset := Vector2(-28.0 * side, randf_range(-6.0, 8.0))
	var to: Vector2 = target.global_position + hit_offset
	var bolt: AnimatedSprite2D = bolt_anim.create_sprite() if bolt_anim else AnimatedSprite2D.new()
	bolt.flip_h = side < 0.0
	battle.add_effect(bolt)
	bolt.global_position = from
	var flight := create_tween()
	flight.tween_property(bolt, "global_position", to, from.distance_to(to) / maxf(bolt_speed, 1.0))
	await flight.finished
	bolt.queue_free()

	target.take_hit(damage, to - from)
	target.wait.knock_back(wait_knock_back)
	battle.fx(impact, to)
	battle.shake(3.0, 0.15)
	_stick_bolt(target, hit_offset, side)
	await user.finish_action()


func _stick_bolt(target: FormigaBattler, at: Vector2, side: float) -> void:
	if stuck_texture == null or target.is_dead():
		return
	var stuck := Sprite2D.new()
	stuck.texture = stuck_texture
	stuck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stuck.scale = Vector2(2, 2)
	stuck.flip_h = side < 0.0
	stuck.z_index = 5
	target.add_child(stuck)
	stuck.position = at + Vector2(-8.0 * side, 0.0)
	var tween := stuck.create_tween()
	tween.tween_interval(stuck_time)
	tween.tween_property(stuck, "modulate:a", 0.0, 0.3)
	tween.tween_callback(stuck.queue_free)
