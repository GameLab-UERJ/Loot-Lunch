extends FormigaSkill
## LANÇAR PEDRA: a formiga cava e arremessa de 1 a `max_stones` pedras (sorteado),
## girando (pedra_projetil).
##
## REUTILIZÁVEL: com `reflect` desligado vira a habilidade básica da Rainha (CORTES DE
## VENTO): a frigideira só DEFENDE (o corte se desfaz), não devolve.
##
## QTE: aperte ESPAÇO quando CADA pedra chegar (um anel por pedra) para REBATER com a
## frigideira (animação `contra_rebater`) — a pedra volta e quebra na formiga
## (`reflect_damage`). Errou = a pedra quebra no chef (pedra_quebrando).
## Martelar o ESPAÇO não funciona: apertar no vazio trava o botão um instante.


@export_range(1, 12) var max_stones: int = 5
## Quantidade (mín, máx) por FASE de quem joga (índice = fase). (0, 0) ou sem item =
## regra normal. Ex.: Rainha na fase final = [(0,0), (8,10)] -> 8 a 10 Cortes de Vento.
@export var stones_by_phase: Array[Vector2i] = []
@export var first_throw: float = 0.55
@export var gap_min: float = 0.4
@export var gap_max: float = 0.75
@export var flight_time: float = 0.7
@export var arc_height: float = 50.0
@export var reflect_damage: int = 1
@export var early_tolerance: float = 0.13
@export var late_tolerance: float = 0.07
@export var whiff_lockout: float = 0.3
## Rebatida devolve o projétil e dá dano em quem jogou. Desligado = só defende.
@export var reflect: bool = true
## De onde sai (em relação a quem joga) e onde chega (em relação ao chef).
@export var throw_offset: Vector2 = Vector2(-36, -10)
@export var aim_offset: Vector2 = Vector2(18, -6)
## Texto do aviso ("%d pedra%s!"). Vazio = sem aviso.
@export var count_text: String = "%d pedra%s!"

@export_group("Arte")
@export var stone_anim: SheetAnimation
@export var break_anim: SheetAnimation
## Fallback sem animação.
@export var stone_texture: Texture2D


var _battle: TurnBattle
var _ant: FormigaBattler
var _chef: ChefBattler
var _stones: Array[Node2D] = []
var _flights: Array[Tween] = []
var _cancelled: bool = false


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	_battle = battle
	_ant = ant
	_chef = chef
	_cancelled = false
	# As últimas da fila jogam mais pedras de uma vez.
	var count: int = randi_range(mini(1 + mini(ant.level / 2, 2), max_stones), max_stones)
	if ant.phase < stones_by_phase.size() and stones_by_phase[ant.phase] != Vector2i.ZERO:
		var span: Vector2i = stones_by_phase[ant.phase]
		count = randi_range(mini(span.x, span.y), maxi(span.x, span.y))
	if count_text != "":
		battle.announce(count_text % [count, "s" if count > 1 else ""], Color(1.0, 0.75, 0.5))

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
	battle.qte.prompt_caption = "REBATA!" if reflect else "DEFENDA!"
	var hits: int = await battle.qte.run(hit_times)
	battle.qte.beat_resolved.disconnect(_on_beat_resolved)
	_cancelled = true  # timers de arremesso que ainda não dispararam não jogam mais nada
	for i in count:
		battle.register_qte(i < hits)
	if hits == count and count > 1:
		battle.announce("Rebateu todas!" if reflect else "Defendeu todos!", Color(0.55, 1.0, 0.55))
		if reflect and not ant.is_dead():
			ant.daze(counter_daze)
	await battle.wait(0.3)
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
	var stone: Node2D = _make_stone()
	_battle.add_effect(stone)
	var from: Vector2 = _ant.global_position + throw_offset
	var to: Vector2 = _chef.global_position + aim_offset
	stone.global_position = from
	_stones[i] = stone
	_ant.squash(Vector2(0.85, 1.15), 0.15)
	var flight := create_tween()
	flight.tween_method(_fly.bind(stone, from, to), 0.0, 1.0, flight_time)
	_flights[i] = flight


func _make_stone() -> Node2D:
	if stone_anim:
		return stone_anim.create_sprite()
	var stone := Sprite2D.new()
	stone.texture = stone_texture
	stone.scale = Vector2(1.5, 1.5)
	stone.z_index = 30
	return stone


## `stone` sem tipo de propósito: a pedra pode ter sido apagada no meio do voo.
func _fly(t: float, stone, from: Vector2, to: Vector2) -> void:
	if is_instance_valid(stone):
		stone.global_position = from.lerp(to, t) + Vector2(0.0, -arc_height * sin(PI * t))


func _on_beat_resolved(i: int, success: bool) -> void:
	if i >= _stones.size():
		return
	var stone: Node2D = _stones[i]
	if _flights[i]:
		_flights[i].kill()
	if not is_instance_valid(stone):
		return
	if success and not reflect:
		_block(stone)
	elif success:
		_rebater(stone)
	else:
		deal(_battle, _ant, _chef, damage, Vector2.LEFT)
		_battle.shake(2.0, 0.12)
		_battle.fx(break_anim, stone.global_position)
		stone.queue_free()


func _rebater(stone: Node2D) -> void:
	# O QTE já acertou: a frigideira bate e a pedra volta voando para a formiga.
	_chef.act(counter_animation, -1)
	var back := create_tween()
	back.tween_property(stone, "global_position", _ant.global_position + Vector2(-10, -8), 0.2)
	await back.finished
	if not is_instance_valid(stone):
		return
	_battle.fx(break_anim, stone.global_position)
	if not _ant.is_dead():
		_ant.take_hit(reflect_damage, Vector2.RIGHT)
	stone.queue_free()


func _block(stone: Node2D) -> void:
	# A frigideira apara: o projétil se desfaz na frente do chef, sem voltar.
	_chef.act(counter_animation, -1)
	_battle.fx(impact if impact else break_anim, stone.global_position)
	stone.queue_free()
