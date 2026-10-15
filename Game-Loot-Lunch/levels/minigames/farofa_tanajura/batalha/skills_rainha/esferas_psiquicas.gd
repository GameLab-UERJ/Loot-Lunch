extends FormigaSkill
## ESFERAS PSÍQUICAS (Rainha, só na FASE FINAL, sai VOANDO): uma CHUVA de esferas cai do
## céu em LINHA RETA. Antes de cada uma, um círculo no chão marca onde ela vai cair.
## O chef pode andar SÓ PARA OS LADOS (◀ ▶ / A D) no espaço dele: da parede da esquerda
## até um pouco antes das formigas (HorizontalDodge). No fim ele volta ao lugar.
## Cada esfera que acerta = `damage`; depois de levar uma, fica `invulnerable_time`
## piscando (não leva duas seguidas).
##
## DESTAQUE (para não sumir no cenário): cada esfera cai maior, com contorno claro
## (SpriteOutline), brilho atrás (GlowHalo) e um rastro; o aviso no chão é mais forte
## e tem borda clara piscando.


@export var orb_count: int = 12
## Segundos em que as esferas vão sendo soltas.
@export var rain_time: float = 5.0
## Aviso no chão antes da queda.
@export var warn_time: float = 0.65
@export var fall_time: float = 0.3
@export var hit_radius: float = 15.0
## Parte das esferas que mira onde o chef está agora (o resto cai em qualquer lugar).
@export_range(0.0, 1.0, 0.05) var aimed_ratio: float = 0.5
@export var invulnerable_time: float = 0.6
## Espaço do chef: da parede (`left_x`) até `gap_to_enemies` px antes da formiga mais perto.
@export var left_x: float = 36.0
@export var gap_to_enemies: float = 70.0
@export var orb_anim: SheetAnimation
@export var splash_anim: SheetAnimation
@export var warn_color: Color = Color(0.75, 0.2, 1.0, 0.8)
@export var zone_color: Color = Color(0.85, 0.55, 1.0, 0.22)

@export_group("Destaque da esfera")
## Tamanho da esfera caindo (a arte é 16 px; 2 = como era antes).
@export var orb_scale: float = 2.6
## Clareia a esfera (1 = cor da arte).
@export var orb_brightness: float = 1.2
## Contorno em volta da esfera. Alfa 0 = sem contorno.
@export var orb_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)
## Brilho redondo atrás da esfera (GlowHalo). Alfa 0 = sem brilho.
@export var orb_glow_color: Color = Color(0.9, 0.3, 1.0, 1.0)
@export var orb_glow_radius: float = 28.0
## Rastro atrás da esfera caindo (pixels de comprimento). 0 = sem rastro.
@export var trail_length: float = 70.0
@export var trail_color: Color = Color(0.95, 0.55, 1.0, 0.75)
## Borda do aviso no chão (pisca).
@export var warn_rim_color: Color = Color(1.0, 0.88, 1.0, 1.0)

@export_group("Áudio")
@export var sfx_plasma_fall: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/plasma_orb_fall.wav")
@export var sfx_plasma_splash: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/plasma_orb_splash.wav")


var _battle: TurnBattle
var _ant: FormigaBattler
var _chef: ChefBattler
var _invulnerable: float = 0.0
var _hits: int = 0
var _running: bool = false


func _init() -> void:
	phases = [1]
	usable_airborne = true


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	_battle = battle
	_ant = ant
	_chef = chef
	_hits = 0
	_invulnerable = 0.0
	battle.announce("CHUVA DE ESFERAS! ◀ ▶ para desviar!", Color(0.85, 0.55, 1.0))

	# Espaço do chef (faixa clara no chão para o jogador ver até onde pode ir).
	var right_x: float = chef.global_position.x + 150.0
	for x in battle.slot_positions().map(func(p: Vector2) -> float: return p.x):
		right_x = minf(right_x, x - gap_to_enemies)
	right_x = maxf(right_x, left_x + 80.0)
	var ground_y: float = chef.feet_position().y
	var zone := Polygon2D.new()
	zone.color = zone_color
	zone.z_index = -5
	zone.polygon = PackedVector2Array([Vector2(left_x - 14, ground_y - 6), Vector2(right_x + 14, ground_y - 6),
		Vector2(right_x + 14, ground_y + 8), Vector2(left_x - 14, ground_y + 8)])
	battle.add_effect(zone)

	var dodge := HorizontalDodge.new()
	dodge.name = "DesvioEsferas"
	battle.add_child(dodge)
	dodge.start(chef, left_x, right_x)
	# Setas em cima do chef (acompanham ele enquanto desvia).
	var prompt := KeyPrompt.spawn(chef, Vector2(0, -60), PackedStringArray(["LEFT", "RIGHT"]), "DESVIE!")
	prompt.set_active(true)
	_running = true
	ant.squash(Vector2(1.15, 0.85), 0.4)
	await battle.wait(0.5)

	# Solta as esferas (cada uma vive sozinha: aviso -> queda -> impacto).
	var gap: float = rain_time / maxf(orb_count, 1)
	for i in orb_count:
		if chef.is_dead() or not battle.running:
			break
		var x: float
		if randf() < aimed_ratio:
			x = clampf(chef.global_position.x + randf_range(-8.0, 8.0), left_x, right_x)
		else:
			x = randf_range(left_x, right_x)
		_drop(x, ground_y)
		await _wait_ticking(gap * randf_range(0.7, 1.3))
	await _wait_ticking(warn_time + fall_time + 0.4)
	_running = false

	prompt.dismiss()
	dodge.stop()
	dodge.queue_free()
	zone.queue_free()
	battle.register_qte(_hits == 0)
	if _hits == 0:
		battle.announce("Desviou de todas!", Color(0.55, 1.0, 0.55))
	if not chef.is_dead():
		await chef.move_to(chef.home_position, 0.35)
		chef.face(chef.global_position + Vector2.RIGHT * 10.0)


## Deixa a esfera fácil de ver no cenário: maior, mais clara, contorno, brilho e rastro.
func _highlight_orb(orb: Node2D) -> void:
	orb.scale = Vector2(orb_scale, orb_scale)
	orb.modulate = Color(orb_brightness, orb_brightness, orb_brightness, 1.0)
	if orb_outline_color.a > 0.0 and (orb is AnimatedSprite2D or orb is Sprite2D):
		SpriteOutline.show_on(orb, orb_outline_color, 1.0)
	if orb_glow_color.a > 0.0:
		GlowHalo.attach(orb, orb_glow_color, orb_glow_radius)
	if trail_length > 0.0:
		var trail := Line2D.new()
		trail.show_behind_parent = true
		# Em coordenadas da esfera (que está escalada): divide pela escala.
		var length: float = trail_length / maxf(orb_scale, 0.01)
		trail.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, -length)])
		trail.width = 20.0 / maxf(orb_scale, 0.01)  # ~20 px na tela
		var fade := Gradient.new()
		fade.set_color(0, trail_color)
		fade.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
		trail.gradient = fade
		var taper := Curve.new()
		taper.add_point(Vector2(0.0, 1.0))
		taper.add_point(Vector2(1.0, 0.2))
		trail.width_curve = taper
		orb.add_child(trail)


## Espera contando o tempo de invulnerabilidade.
func _wait_ticking(seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		await _battle.get_tree().process_frame
		var delta: float = _battle.get_process_delta_time()
		left -= delta
		_invulnerable = maxf(_invulnerable - delta, 0.0)


func _drop(x: float, ground_y: float) -> void:
	# 1. Aviso no chão (cresce até a queda).
	var mark := Polygon2D.new()
	var points := PackedVector2Array()
	for k in 16:
		var a: float = TAU * k / 16.0
		points.append(Vector2(cos(a) * hit_radius, sin(a) * hit_radius * 0.35))
	mark.polygon = points
	mark.color = warn_color
	mark.z_index = -4
	if warn_rim_color.a > 0.0:
		var rim := Line2D.new()
		rim.points = points
		rim.closed = true
		rim.width = 2.0
		rim.default_color = warn_rim_color
		mark.add_child(rim)
		var blink := rim.create_tween().set_loops()
		blink.tween_property(rim, "modulate:a", 0.35, 0.12)
		blink.tween_property(rim, "modulate:a", 1.0, 0.12)
	mark.add_to_group(&"esfera_aviso")
	mark.set_meta(&"impact_time", Time.get_ticks_msec() / 1000.0 + warn_time + fall_time)
	_battle.add_effect(mark)
	mark.global_position = Vector2(x, ground_y)
	mark.scale = Vector2(0.3, 0.3)
	var grow := mark.create_tween()
	grow.tween_property(mark, "scale", Vector2.ONE, warn_time + fall_time)
	await _battle.wait(warn_time)

	# 2. Queda em linha reta.
	var orb: Node2D = orb_anim.create_sprite() if orb_anim else Node2D.new()
	_highlight_orb(orb)
	_battle.add_effect(orb)
	_battle.play_sfx(sfx_plasma_fall, randf_range(0.95, 1.05))
	var hit_y: float = ground_y - 14.0
	orb.global_position = Vector2(x, -30.0)
	var fall := orb.create_tween()
	fall.tween_property(orb, "global_position:y", hit_y, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished

	# 3. Impacto.
	orb.queue_free()
	mark.queue_free()
	_battle.play_sfx(sfx_plasma_splash, randf_range(0.95, 1.05))
	if splash_anim:
		_battle.fx(splash_anim, Vector2(x, hit_y))
	if not _running or _chef.is_dead():
		return
	if absf(_chef.global_position.x - x) <= hit_radius + 6.0 and _invulnerable <= 0.0:
		_hits += 1
		_invulnerable = invulnerable_time
		deal(_battle, _ant, _chef, damage, Vector2.DOWN)
		_battle.shake(3.0, 0.15)
