extends Node
class_name QteTrack
## QTE de TIMING: uma ou mais "batidas" em momentos marcados. O jogador aperta a ação
## (ESPAÇO) na hora de cada batida. Não sabe o que é investida, terremoto ou pedra:
## só mede o tempo e avisa quem acertou.
##
##   var acertos: int = await qte.run([0.8])               # 1 batida daqui a 0.8 s
##   var acertos: int = await qte.run([0.7, 1.3, 1.8])     # 3 pedras
##
## Regras ajustáveis no Inspector (ou por código antes do `run`):
##   - janela = [impacto - early_tolerance, impacto + late_tolerance]
##   - `early_press_fails`: apertou CEDO (antes da janela) = perdeu a batida. É o
##     "só há uma oportunidade" da investida da formiga.
##   - `whiff_lockout`: apertou no vazio = botão travado um instante. Castiga quem fica
##     martelando o ESPAÇO nas pedras.
##
## Com `ring_anchor` definido, desenha um QteRing por batida em volta dele e, em cima,
## a TECLA da ação (KeyPrompt: "ESPAÇO" + `prompt_caption`), que acende quando a janela
## abre. Quem usa troca o texto antes do `run` (ex.: `qte.prompt_caption = "PULE!"`).
## Reutilizável: defesa, parry, ritmo, cozinhar no compasso...


signal beat_opened(index: int)
signal beat_resolved(index: int, success: bool)
## Apertou fora de qualquer janela (só quando não perde a batida por isso).
signal whiffed
## Todas as batidas resolvidas. `successes` = quantas acertou.
signal finished(successes: int)


enum BeatState { PENDING, OPEN, HIT, MISSED }


@export var action: StringName = &"chef_pick_drop"
@export_range(0.02, 1.0, 0.01, "suffix:s") var early_tolerance: float = 0.16
@export_range(0.0, 1.0, 0.01, "suffix:s") var late_tolerance: float = 0.08
@export var early_press_fails: bool = true
## Quão antes da janela um aperto ainda conta como "cedo demais" (antes disso é ignorado).
@export_range(0.0, 3.0, 0.05, "suffix:s") var attention_time: float = 0.6
@export_range(0.0, 1.0, 0.01, "suffix:s") var whiff_lockout: float = 0.0
## Multiplica as janelas que vêm do `configure()` (1.5 = 50% mais tempo para acertar).
## Um botão só para deixar a etapa inteira mais fácil ou mais difícil.
@export_range(0.5, 3.0, 0.05) var window_scale: float = 1.0

@export_group("Anéis")
@export var ring_anchor: Node2D
@export var ring_offset: Vector2 = Vector2.ZERO
## Segundos que o anel leva fechando até o impacto.
@export var ring_approach: float = 0.8

@export_group("Tecla na tela")
## Mostra a TECLA da ação em cima de `ring_anchor` enquanto o QTE roda (aparece junto
## com o primeiro anel e acende quando a janela de acerto abre).
@export var show_key_prompt: bool = true
## Posição da tecla em relação ao `ring_anchor`.
@export var key_prompt_offset: Vector2 = Vector2(0, -60)


## Texto em cima da tecla ("REBATA!", "PULE!"). Volta a "" quando o QTE acaba.
var prompt_caption: String = ""


var _hits: Array[float] = []
## Estado de cada batida (valores de BeatState).
var _states: Array[int] = []
var _rings: Array[QteRing] = []
var _time: float = 0.0
var _lockout: float = 0.0
var _running: bool = false
var _successes: int = 0
var _prompt: KeyPrompt = null


func is_running() -> bool:
	return _running


## Ajusta as regras de uma vez (cada ataque inimigo tem as suas).
func configure(early: float, late: float, early_fails: bool, attention: float = 0.6,
		lockout: float = 0.0) -> void:
	early_tolerance = early * window_scale
	late_tolerance = late * window_scale
	early_press_fails = early_fails
	attention_time = attention
	whiff_lockout = lockout


## Começa e ESPERA o fim. Retorna quantas batidas acertou.
func run(hit_times: Array[float]) -> int:
	start(hit_times)
	if not _running:
		return _successes
	return await finished


## Começa sem esperar (escute `beat_resolved` / `finished`).
func start(hit_times: Array[float]) -> void:
	var caption: String = prompt_caption  # o cancel() limpa o texto: guarda o de agora
	cancel()
	prompt_caption = caption
	_hits = hit_times.duplicate()
	_hits.sort()
	_states.clear()
	_rings.clear()
	_time = 0.0
	_lockout = 0.0
	_successes = 0
	for i in _hits.size():
		_states.append(BeatState.PENDING)
		_rings.append(null)
	_running = not _hits.is_empty()
	if not _running:
		finished.emit(0)


## Interrompe agora (ex.: quem atacava morreu no meio). Quem estava esperando o `run`
## recebe `finished` com os acertos até aqui (ninguém fica preso no `await`).
func cancel() -> void:
	var was_running: bool = _running
	_running = false
	_hide_prompt()
	for ring in _rings:
		if is_instance_valid(ring):
			ring.queue_free()
	_rings.clear()
	if was_running:
		finished.emit(_successes)


## Segundos até a próxima batida pendente (útil para animar quem ataca). -1 = nenhuma.
func time_to_next_hit() -> float:
	for i in _hits.size():
		if _states[i] == BeatState.PENDING or _states[i] == BeatState.OPEN:
			return _hits[i] - _time
	return -1.0


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	_lockout = maxf(_lockout - delta, 0.0)
	for i in _hits.size():
		if not _running:
			break  # alguém cancelou ao ouvir `beat_resolved`
		var state: int = _states[i]
		if state == BeatState.HIT or state == BeatState.MISSED:
			continue
		if _rings[i] == null and ring_anchor and _time >= _hits[i] - ring_approach:
			_rings[i] = _spawn_ring(_hits[i] - _time)
		if state == BeatState.PENDING and _time >= _hits[i] - early_tolerance:
			_states[i] = BeatState.OPEN
			beat_opened.emit(i)
		if _time > _hits[i] + late_tolerance:
			_resolve(i, false)
	_update_prompt()
	_check_finished()


func _unhandled_input(event: InputEvent) -> void:
	if not _running or action == &"" or not InputMap.has_action(action):
		return
	if event.is_action_pressed(action) and not event.is_echo():
		press()
		get_viewport().set_input_as_handled()


## O jogador apertou (público para IA/testes).
func press() -> void:
	if not _running or _lockout > 0.0:
		return
	var i: int = _next_pending()
	if i < 0:
		return
	var dt: float = _time - _hits[i]
	if dt >= -early_tolerance and dt <= late_tolerance:
		_resolve(i, true)
		_check_finished()
		return
	if dt < -early_tolerance and dt >= -(early_tolerance + attention_time) and early_press_fails:
		_resolve(i, false)
		_check_finished()
		return
	if whiff_lockout > 0.0:
		_lockout = whiff_lockout
	whiffed.emit()


func _next_pending() -> int:
	for i in _hits.size():
		if _states[i] == BeatState.PENDING or _states[i] == BeatState.OPEN:
			return i
	return -1


func _resolve(i: int, success: bool) -> void:
	_states[i] = BeatState.HIT if success else BeatState.MISSED
	if success:
		_successes += 1
	if is_instance_valid(_rings[i]):
		_rings[i].resolve(success)
	beat_resolved.emit(i, success)


func _check_finished() -> void:
	if _running and _next_pending() < 0:
		_running = false
		_hide_prompt()
		finished.emit(_successes)


## A tecla aparece junto com o primeiro anel e acende enquanto alguma janela está aberta.
func _update_prompt() -> void:
	if not _running or not show_key_prompt or ring_anchor == null:
		return
	var next: int = _next_pending()
	if next < 0:
		return
	if _prompt == null and _time >= _hits[next] - ring_approach:
		var key: String = KeyCap.key_for_action(action)
		if key != "":
			_prompt = KeyPrompt.spawn(ring_anchor, ring_offset + key_prompt_offset,
				PackedStringArray([key]), prompt_caption)
	if is_instance_valid(_prompt):
		_prompt.set_active(_states[next] == BeatState.OPEN)


func _hide_prompt() -> void:
	if is_instance_valid(_prompt):
		_prompt.dismiss()
	_prompt = null
	prompt_caption = ""


func _spawn_ring(time_to_hit: float) -> QteRing:
	var ring := QteRing.new()
	ring.position = ring_offset
	ring_anchor.add_child(ring)
	ring.setup(maxf(time_to_hit, 0.01), early_tolerance, late_tolerance)
	return ring
