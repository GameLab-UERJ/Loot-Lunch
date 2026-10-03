extends Node
class_name TurnBattle
## BATALHA EM TEMPO ATIVO (estilo ATB dos RPGs clássicos) da Fase 3: o chef contra as
## 5 tanajuras AO MESMO TEMPO.
##
## SISTEMA DE ESPERA: cada lutador tem um BattleWaitComponent. O relógio corre e as
## barras enchem; quem encher age:
##   - CHEF cheio  -> o BattleMenu libera as 4 habilidades (teclas 1-4 ou clique) e o
##                    chef ataca o ALVO marcado (◀ ▶ / A D trocam, ou clique na formiga)
##   - FORMIGA cheia -> "!" em cima dela e ela ataca; cada ataque é um QTE de defesa
## Enquanto alguém ataca o relógio PARA (um golpe de cada vez, sem QTE embolado).
## Com `active_time` o relógio NÃO para com o menu aberto: pensou demais, apanha.
##
## Apertou a habilidade antes da barra encher? Fica AGENDADA e sai assim que encher.
##
## `await battle.run()` devolve true (venceu todas) ou false (o chef caiu).
## As habilidades recebem a batalha para usar o QTE, os avisos, o tremor e a arena.


signal ant_entered(ant: FormigaBattler)
signal ant_defeated(ant: FormigaBattler, index: int)
signal target_changed(ant: FormigaBattler)
signal battle_finished(victory: bool)


@export var chef: ChefBattler
@export var menu: BattleMenu
@export var qte: QteTrack
@export var banner: MinigameBanner
## Onde as habilidades criam efeitos (pedras, ondas, buracos, sombra...).
@export var arena: Node2D
## Nó que treme nos impactos (normalmente a raiz da etapa).
@export var shake_target: Node2D
## Marcador do alvo (desenhado em cima da formiga escolhida).
@export var target_cursor: TargetCursor

@export_group("Tempo")
## O relógio continua correndo com o menu aberto (mais difícil e mais fluido).
@export var active_time: bool = true
## Quanto tempo o "!" fica em cima da formiga antes do ataque.
@export_range(0.0, 2.0, 0.05, "suffix:s") var alert_time: float = 0.45
## Respiro depois de cada ação.
@export_range(0.0, 2.0, 0.05, "suffix:s") var action_pause: float = 0.15
## Ninguém ataca nos primeiros segundos (o jogador se situa).
@export_range(0.0, 5.0, 0.1, "suffix:s") var opening_grace: float = 1.0


var ants: Array[FormigaBattler] = []
var defeated: Array[FormigaBattler] = []
var target: FormigaBattler = null
## Estatística de QTEs (o VIP avalia a elegância da luta).
var qte_successes: int = 0
var qte_total: int = 0
var running: bool = false
var _queued_skill: BattleSkill = null
var _busy: bool = false
var _shake_tween: Tween
var _shake_origin: Vector2


func setup(queue: Array[FormigaBattler]) -> void:
	ants = queue.duplicate()
	defeated.clear()
	for i in ants.size():
		var ant: FormigaBattler = ants[i]
		ant.level = i
		ant.display_name = "Tanajura %d" % (i + 1)
		ant.clicked.connect(select_target)
		ant.set_targetable(true)
		if ant.hp_bar:
			ant.hp_bar.set_bar_visible(true)
		ant.face(chef.global_position, ant.art_faces_left)
		ant_entered.emit(ant)
	if shake_target:
		_shake_origin = shake_target.position
	if menu:
		if not menu.skill_chosen.is_connected(_on_skill_chosen):
			menu.skill_chosen.connect(_on_skill_chosen)
		if not menu.target_step.is_connected(cycle_target):
			menu.target_step.connect(cycle_target)


func run() -> bool:
	running = true
	chef.show_wait_bar(true)
	select_target(_first_alive())
	menu.open(chef, target)
	var grace: float = opening_grace
	while true:
		if chef.is_dead():
			return _end(false)
		if alive_ants().is_empty():
			return _end(true)

		# 1. Formiga com a espera cheia ataca (uma de cada vez).
		var ant: FormigaBattler = _next_ready_ant() if grace <= 0.0 else null
		if ant:
			await _ant_turn(ant)
			continue

		# 2. Chef com a espera cheia e uma habilidade escolhida (ou agendada).
		if chef.wait.is_ready() and _queued_skill:
			var skill: BattleSkill = _queued_skill
			_queued_skill = null
			menu.set_queued(null)
			if skill.can_use(chef, target):
				await _chef_turn(skill)
				continue
			menu.show_reason(skill)

		# 3. O relógio anda.
		await get_tree().process_frame
		if not running:
			return false
		var delta: float = get_process_delta_time()
		grace = maxf(grace - delta, 0.0)
		_tick(delta)
	return false


func stop() -> void:
	running = false
	if menu:
		menu.close()
	if target_cursor:
		target_cursor.hide()


func alive_ants() -> Array[FormigaBattler]:
	var alive: Array[FormigaBattler] = []
	for ant in ants:
		if is_instance_valid(ant) and not ant.is_dead():
			alive.append(ant)
	return alive


# --- Alvo --------------------------------------------------------------------------

func select_target(ant: FormigaBattler) -> void:
	if ant != null and ant.is_dead():
		ant = null
	target = ant
	if target_cursor:
		target_cursor.follow(target, target.head_offset + Vector2(0, -14) if target else Vector2.ZERO)
	if menu:
		menu.set_target(target)
	target_changed.emit(target)


## Próximo/anterior alvo vivo (de cima para baixo, da frente para trás).
func cycle_target(step: int) -> void:
	var alive: Array[FormigaBattler] = alive_ants()
	if alive.is_empty():
		return
	alive.sort_custom(func(a: FormigaBattler, b: FormigaBattler) -> bool:
		return a.home_position.y < b.home_position.y if not is_equal_approx(a.home_position.y, b.home_position.y) \
			else a.home_position.x < b.home_position.x)
	var index: int = alive.find(target)
	index = 0 if index < 0 else wrapi(index + step, 0, alive.size())
	select_target(alive[index])


# --- Ferramentas para as habilidades -------------------------------------------

## Aviso curto no alto da tela.
func announce(text: String, color: Color = Color.WHITE) -> void:
	if banner:
		banner.toast(text, color)


## Conta um QTE de defesa (para a nota final).
func register_qte(success: bool) -> void:
	qte_total += 1
	if success:
		qte_successes += 1


func get_qte_ratio() -> float:
	return float(qte_successes) / float(qte_total) if qte_total > 0 else 1.0


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Tremor de tela (impacto de terremoto, trombada...).
func shake(strength: float = 3.0, duration: float = 0.25) -> void:
	if shake_target == null:
		return
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps: int = maxi(int(duration / 0.04), 2)
	for i in steps:
		var falloff: float = 1.0 - float(i) / steps
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff
		_shake_tween.tween_property(shake_target, "position", _shake_origin + offset, 0.04)
	_shake_tween.tween_property(shake_target, "position", _shake_origin, 0.04)


func add_effect(node: Node) -> void:
	(arena if arena else shake_target).add_child(node)


## Toca um efeito (SheetAnimation) UMA vez na arena. `follow` = anda junto com o nó.
func fx(anim: SheetAnimation, at: Vector2, follow: Node2D = null) -> AnimatedSprite2D:
	return SheetAnimation.spawn_once(anim, arena if arena else shake_target, at, follow)


# --- Fluxo -----------------------------------------------------------------------

func _tick(delta: float) -> void:
	var menu_waiting: bool = chef.wait.is_ready() and _queued_skill == null
	if not chef.wait.is_ready():
		chef.wait.tick(delta)
		if chef.wait.is_ready():
			menu.set_ready(true)
	if menu_waiting and not active_time:
		return  # modo "espera": o tempo para enquanto o jogador escolhe
	for ant in alive_ants():
		ant.wait.tick(delta)


func _next_ready_ant() -> FormigaBattler:
	var best: FormigaBattler = null
	for ant in alive_ants():
		if ant.wait.is_ready() and (best == null or ant.wait.elapsed - ant.wait.current_wait \
				> best.wait.elapsed - best.wait.current_wait):
			best = ant
	return best


func _on_skill_chosen(skill: BattleSkill) -> void:
	_queued_skill = skill
	menu.set_queued(skill)


func _chef_turn(skill: BattleSkill) -> void:
	_busy = true
	menu.lock(true)
	var aimed: FormigaBattler = target
	await skill.execute(self, chef, aimed)
	chef.wait.consume()
	menu.set_ready(false)
	await _reap_dead()
	await wait(action_pause)
	menu.lock(false)
	_busy = false


func _ant_turn(ant: FormigaBattler) -> void:
	_busy = true
	menu.lock(true)
	ant.show_alert(true)
	await wait(alert_time)
	ant.show_alert(false)
	if not ant.is_dead() and not chef.is_dead():
		var attack: FormigaSkill = ant.choose_skill()
		if attack:
			await attack.execute(self, ant, chef)
	ant.wait.consume()
	await _reap_dead()
	await wait(action_pause)
	menu.lock(false)
	_busy = false


## Formigas que caíram durante a ação: animação de nocaute + drop.
func _reap_dead() -> void:
	for ant in ants:
		if not is_instance_valid(ant) or not ant.is_dead() or defeated.has(ant):
			continue
		var index: int = defeated.size()
		defeated.append(ant)
		if ant.devoured:
			ant.global_position = ant.home_position
		else:
			announce("%s nocauteada!" % ant.display_name, Color(0.55, 1.0, 0.55))
		await ant.play_death()
		ant_defeated.emit(ant, index)
	if target == null or target.is_dead():
		select_target(_first_alive())


func _first_alive() -> FormigaBattler:
	var alive: Array[FormigaBattler] = alive_ants()
	if alive.is_empty():
		return null
	alive.sort_custom(func(a: FormigaBattler, b: FormigaBattler) -> bool:
		return a.global_position.x < b.global_position.x)
	return alive[0]


func _end(victory: bool) -> bool:
	stop()
	chef.show_wait_bar(false)
	if not victory:
		announce("O chef desmaiou...", Color(1.0, 0.4, 0.4))
	battle_finished.emit(victory)
	return victory
