extends BattleSkill
## 3. BOLO DE FOGO: magia clássica de dano à distância. O chef dá um pulinho e
## arremessa uma bola de fogo em arco que explode na formiga.


@export var damage: int = 13
## Animação da bola (art/anim/bola_fogo_anim.tres).
@export var fireball: SheetAnimation
@export var flight_time: float = 0.45
@export var arc_height: float = 40.0
@export var ball_scale: Vector2 = Vector2(2, 2)


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.hop(10.0, 0.2)

	var ball: AnimatedSprite2D = fireball.create_sprite() if fireball else AnimatedSprite2D.new()
	ball.scale = ball_scale
	ball.z_index = 30
	battle.add_effect(ball)
	var from: Vector2 = user.global_position + Vector2(16, -12)
	var to: Vector2 = target.global_position + Vector2(0, -8)
	ball.global_position = from
	var tween := create_tween()
	tween.tween_method(_fly.bind(ball, from, to), 0.0, 1.0, flight_time)
	await tween.finished

	# Explosão: a bola incha e some.
	var boom := create_tween().set_parallel(true)
	boom.tween_property(ball, "scale", ball_scale * 2.5, 0.2)
	boom.tween_property(ball, "modulate", Color(2.0, 1.5, 0.6, 0.0), 0.2)
	boom.chain().tween_callback(ball.queue_free)
	target.take_hit(damage, to - from)
	target.flash(Color(3.0, 1.6, 0.6))
	battle.shake(5.0, 0.25)
	await battle.wait(0.35)


func _fly(t: float, ball, from: Vector2, to: Vector2) -> void:
	if not is_instance_valid(ball):
		return
	ball.global_position = from.lerp(to, t) + Vector2(0.0, -arc_height * sin(PI * t))
