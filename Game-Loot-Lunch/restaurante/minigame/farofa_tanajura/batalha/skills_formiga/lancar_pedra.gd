extends FormigaSkill
## LANÇAR PEDRA: a formiga cava e arremessa de 1 a `max_stones` pedras (sorteado).
##
## QTE: aperte ESPAÇO quando CADA pedra chegar (um anel por pedra) para rebater com a
## frigideira — a pedra rebatida volta e acerta a formiga (`reflect_damage`).
## Martelar o ESPAÇO não funciona: apertar no vazio trava o botão um instante.


@export var stone_texture: Texture2D
@export_range(1, 5) var max_stones: int = 5
@export var first_throw: float = 0.6
@export var gap_min: float = 0.45
@export var gap_max: float = 0.8
@export var flight_time: float = 0.75
@export var arc_height: float = 50.0
@export var reflect_damage: int = 1
@export var early_tolerance: float = 0.13
@export var late_tolerance: float = 0.07
@export var whiff_lockout: float = 0.3


var _battle: TurnBattle
var _ant: FormigaBattler
var _chef: ChefBattler
var _stones: Array[Sprite2D] = []
var _flights: Array[Tween] = []
var _cancelled: bool = false


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	_battle = battle
	_ant = ant
	_chef = chef
	_cancelled = false
	var count: int = randi_range(1, max_stones)
	battle.announce("%d pedra%s!" % [count, "s" if count > 1 else ""], Color(1.0, 0.75, 0.5))

	var hit_times: Array[float] = []
	var throw_time: float = first_throw
	_stones.clear()
	_flights.clear()
	for i in count:
		hit_times.append(throw_time + flight_time)
		_stones.append(null)
		_flights.append(null)
		get_tree().create_timer(throw_time, false).timeout.connect(_throw.bind(i))
		throw_time += randf_range(gap_min, gap_max)

	ant.squash(Vector2(1.2, 0.8), 0.4)  # cavando
	battle.qte.configure(early_tolerance, late_tolerance, false, 0.0, whiff_lockout)
	battle.qte.ring_anchor = chef.qte_anchor
	battle.qte.beat_resolved.connect(_on_beat_resolved)
	var hits: int = await battle.qte.run(hit_times)
	battle.qte.beat_resolved.disconnect(_on_beat_resolved)
	for i in count:
		battle.register_qte(i < hits)
	if hits == count and count > 1:
		battle.announce("Rebateu todas!", Color(0.55, 1.0, 0.55))
	await battle.wait(0.35)
	for flight in _flights:
		if flight:
			flight.kill()
	for stone in _stones:
		if is_instance_valid(stone):
			stone.queue_free()


func _throw(i: int) -> void:
	if _cancelled:
		return
	if _ant.is_dead():
		# A formiga caiu com uma pedra rebatida: o resto não sai.
		_cancelled = true
		_battle.qte.cancel()
		return
	var stone := Sprite2D.new()
	stone.texture = stone_texture
	stone.scale = Vector2(1.5, 1.5)
	stone.z_index = 30
	_battle.add_effect(stone)
	var from: Vector2 = _ant.global_position + Vector2(-10, -10)
	var to: Vector2 = _chef.global_position + Vector2(8, -10)
	stone.global_position = from
	_stones[i] = stone
	_ant.squash(Vector2(0.85, 1.15), 0.15)
	var flight := create_tween()
	flight.tween_method(_fly.bind(stone, from, to), 0.0, 1.0, flight_time)
	_flights[i] = flight


## `stone` sem tipo de propósito: a pedra pode ter sido apagada no meio do voo.
func _fly(t: float, stone, from: Vector2, to: Vector2) -> void:
	if is_instance_valid(stone):
		stone.global_position = from.lerp(to, t) + Vector2(0.0, -arc_height * sin(PI * t))
		stone.rotation = -t * TAU


func _on_beat_resolved(i: int, success: bool) -> void:
	if _cancelled or i >= _stones.size():
		return
	var stone: Sprite2D = _stones[i]
	if _flights[i]:
		_flights[i].kill()
	if not is_instance_valid(stone):
		return
	if success:
		_chef.swing_pan(_ant.global_position - _chef.global_position)
		var back := create_tween()
		back.tween_property(stone, "global_position", _ant.global_position + Vector2(0, -8), 0.22)
		back.tween_callback(func() -> void:
			if not _ant.is_dead():
				_ant.take_hit(reflect_damage, Vector2.RIGHT)
			stone.queue_free())
	else:
		_chef.take_hit(damage, Vector2.LEFT)
		_battle.shake(2.0, 0.12)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(stone, "global_position", stone.global_position + Vector2(-12, 18), 0.25)
		fall.tween_property(stone, "modulate:a", 0.0, 0.25)
		fall.chain().tween_callback(stone.queue_free)
