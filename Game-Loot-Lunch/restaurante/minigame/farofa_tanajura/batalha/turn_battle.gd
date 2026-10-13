extends Node
class_name TurnBattle
## BATALHA EM TEMPO ATIVO (estilo ATB dos RPGs clássicos) da Fase 3: o chef contra a
## TANAJURA RAINHA (chefe) e as tanajuras pequenas dela, AO MESMO TEMPO.
##
## SISTEMA DE ESPERA: cada lutador tem um BattleWaitComponent. O relógio corre e as
## barras enchem; quem encher age:
##   - CHEF cheio  -> o BattleMenu libera as 4 habilidades (teclas 1-4 ou clique) e o
##                    chef ataca o ALVO marcado (◀ ▶ / A D trocam, ou clique na formiga)
##   - FORMIGA cheia -> "!" em cima dela e ela ataca; cada ataque é um QTE de defesa
## Enquanto alguém ataca (ou conjura) o relógio PARA: as outras formigas esperam.
## Habilidade com `interrupts` (prioridade máxima) sai na hora, sem esperar a barra.
## Com `active_time` o relógio NÃO para com o menu aberto: pensou demais, apanha.
## Exceção: `channel()` — a Rainha carregando o Ultra Arremesso: só o CHEF age.
##
## Apertou a habilidade antes da barra encher? Fica AGENDADA e sai assim que encher.
##
## Com chefe (`is_boss`), a luta acaba quando ELE cai (as pequenas fogem). Sem chefe,
## quando todas caírem. `await battle.run()` devolve true (venceu) ou false (o chef caiu).


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
## Barra de vida do chefe no topo da tela (opcional).
@export var boss_bar: BossHealthBar
## Contorno (aura) em volta da formiga que está na mira, igual ao destaque dos itens
## da cozinha (SpriteOutline). Pisca de leve.
@export var target_outline_color: Color = Color.WHITE
@export var target_outline_width: float = 2.0

@export_group("Formigas pequenas")
## Cena da formiga pequena (para as invocações do chefe).
@export var ant_scene: PackedScene
## Vagas das formigas pequenas (filhos Marker2D). Nunca há mais pequenas que vagas.
@export var formation: Node2D
## Onde os drops (bundas) ficam guardados durante a luta.
@export var drop_pile: Marker2D
@export var drop_pile_spacing: Vector2 = Vector2(14, -6)
## Com o chefe voando, as pequenas dão `rage_multiplier` x o dano.
@export_range(1, 5) var rage_multiplier: int = 2

@export_group("Tempo")
## RITMO DA LUTA: multiplica a velocidade com que as barras de espera enchem (chef e
## formigas). 1.25 = todo mundo ataca 25% mais vezes. Os QTEs não mudam.
@export_range(0.25, 4.0, 0.05) var attack_speed: float = 1.25
## Velocidade das ANIMAÇÕES durante a luta (Engine.time_scale). 1 = normal. Acima de 1
## os golpes ficam mais rápidos, mas as janelas dos QTEs também encurtam.
@export_range(0.5, 3.0, 0.05) var animation_speed: float = 1.0
## VEZ DO CHEF: a barra dele encheu e nenhuma habilidade estava agendada -> o tempo das
## formigas PARA (igual durante o ataque delas) até ele escolher.
@export var pause_on_chef_turn: bool = true
## Segundos (reais) para escolher. Passou disso, o chef PERDE A VEZ e o tempo volta.
@export_range(1.0, 30.0, 0.5, "suffix:s") var decision_time: float = 5.0
## O relógio continua correndo com o menu aberto (mais difícil e mais fluido).
## Ignorado na vez do chef quando `pause_on_chef_turn` está ligado.
@export var active_time: bool = true
## Quanto tempo o "!" fica em cima da formiga antes do ataque.
@export_range(0.0, 2.0, 0.05, "suffix:s") var alert_time: float = 0.7
## Respiro depois de cada ação.
@export_range(0.0, 2.0, 0.05, "suffix:s") var action_pause: float = 0.15
## Ninguém ataca nos primeiros segundos (o jogador se situa).
@export_range(0.0, 5.0, 0.1, "suffix:s") var opening_grace: float = 1.5


var ants: Array[FormigaBattler] = []
var defeated: Array[FormigaBattler] = []
var boss: QueenAntBattler = null
var target: FormigaBattler = null
## Drops guardados na pilha (vão para a farofa no fim).
var drops: Array[Sprite2D] = []
## Estatística de QTEs (o VIP avalia a elegância da luta).
var qte_successes: int = 0
var qte_total: int = 0
var running: bool = false
var _queued_skill: BattleSkill = null
var _busy: bool = false
var _channeling: bool = false
var _chef_acting: bool = false
var _shake_tween: Tween
var _shake_origin: Vector2
## Contador de nomes por tipo ("Tanajura 3", "Guardiã 1"...).
var _name_counters: Dictionary = {}
var _outlined: FormigaBattler = null
var _outline_tween: Tween
## Quem está agindo agora (para a barra de turnos destacar). null = ninguém.
var acting: Battler = null
## Vez do chef aberta (tempo parado esperando a escolha) e segundos que restam.
var deciding: bool = false
var decision_left: float = 0.0
var _saved_time_scale: float = 1.0


func setup(queue: Array[FormigaBattler]) -> void:
	ants.clear()
	defeated.clear()
	for ant in queue:
		register_ant(ant)
	if shake_target:
		_shake_origin = shake_target.position
	if menu:
		if not menu.skill_chosen.is_connected(_on_skill_chosen):
			menu.skill_chosen.connect(_on_skill_chosen)
		if not menu.target_step.is_connected(cycle_target):
			menu.target_step.connect(cycle_target)


## Coloca uma formiga na luta (as do começo e as invocadas pelo chefe).
func register_ant(ant: FormigaBattler) -> void:
	if ants.has(ant):
		return
	ants.append(ant)
	if ant.is_boss:
		boss = ant as QueenAntBattler
		if boss_bar:
			boss_bar.track(boss, boss.boss_title)
			boss.status_changed.connect(boss_bar.set_status)
		if boss:
			boss.flight_changed.connect(_on_boss_flight_changed)
			boss.protection_changed.connect(_on_boss_protection_changed)
	else:
		ant.level = clampi(ant.slot_index, 0, 4)
		var number: int = int(_name_counters.get(ant.name_prefix, 0)) + 1
		_name_counters[ant.name_prefix] = number
		ant.display_name = "%s %d" % [ant.name_prefix, number]
		ant.set_enraged(is_boss_airborne())
		if ant.protects_boss and boss and not boss.is_dead():
			boss.add_guardian(ant)
	ant.clicked.connect(select_target)
	ant.set_targetable(ant.can_be_targeted())
	if ant.hp_bar:
		ant.hp_bar.set_bar_visible(true)
	ant.face(chef.global_position, ant.art_faces_left)
	ant_entered.emit(ant)


func run() -> bool:
	running = true
	_saved_time_scale = Engine.time_scale
	Engine.time_scale = animation_speed
	chef.show_wait_bar(true)
	select_target(_first_alive())
	menu.open(chef, target)
	var grace: float = opening_grace
	while true:
		if chef.is_dead():
			return await _end(false)
		if _is_won():
			return await _end(true)

		_update_decision_state()

		# 0. A Rainha cansou de voar: desce (momento seguro, ninguém atacando).
		if boss and boss.airborne and boss.flight_left <= 0.0:
			await boss.land()
			continue

		# 1. PRIORIDADE MÁXIMA (ex.: Devorar e Conjurar da Rainha com a vida baixa): sai
		#    agora, sem esperar a barra; as outras formigas e o chef esperam.
		var urgent: FormigaBattler = _next_interrupting_ant()
		if urgent:
			await _ant_turn(urgent, urgent.interrupting_skill(self))
			continue

		# 2. Formiga com a espera cheia ataca (uma de cada vez). Na VEZ DO CHEF elas
		#    esperam: o tempo está parado até ele escolher.
		var ant: FormigaBattler = _next_ready_ant() if grace <= 0.0 and not deciding else null
		if ant:
			await _ant_turn(ant)
			continue

		# 3. Chef com a espera cheia e uma habilidade escolhida (ou agendada).
		if await _try_chef_turn():
			continue

		# 4. O relógio anda (ou, na vez do chef, só a contagem de decisão).
		await get_tree().process_frame
		if not running:
			return false
		var delta: float = get_process_delta_time()
		if deciding:
			# Conta em segundos REAIS (não depende do animation_speed).
			decision_left -= delta / maxf(Engine.time_scale, 0.001)
			menu.set_countdown(maxf(decision_left, 0.0))
			if decision_left <= 0.0 and _queued_skill == null:
				await _chef_skip_turn()
			continue
		grace = maxf(grace - delta, 0.0)
		_tick(delta * attack_speed)
	return false


## Abre/fecha a VEZ DO CHEF (tempo parado + contagem de `decision_time`).
func _update_decision_state() -> void:
	var now: bool = pause_on_chef_turn and running and not chef.is_dead() \
			and chef.wait.is_ready() and _queued_skill == null
	if now and not deciding:
		decision_left = decision_time
		menu.set_countdown(decision_left)
	elif not now and deciding:
		menu.set_countdown(-1.0)
	deciding = now


## Acabou o tempo de escolher: o chef perde a vez e o relógio volta a andar.
func _chef_skip_turn() -> void:
	deciding = false
	menu.set_countdown(-1.0)
	chef.wait.consume()
	menu.set_ready(false)
	announce("Tempo esgotado! O chef perdeu a vez.", Color(1.0, 0.6, 0.35))
	FloatingText.spawn(chef.get_parent(), chef.global_position + Vector2(0, -48), "Perdeu a vez!", Color(1.0, 0.6, 0.35))
	await wait(action_pause)


## ORDEM DOS TURNOS (para a TurnOrderBar). Cada item:
##   battler, ratio (0..1 da espera), eta (segundos até agir; INF = não age),
##   ally (é o chef), boss, stunned, acting (agindo agora), deciding (vez do chef aberta),
##   order (1 = o próximo a agir; 0 = não age).
func turn_order() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if chef == null:
		return list
	var everyone: Array[Battler] = [chef]
	for ant in alive_ants():
		everyone.append(ant)
	for b in everyone:
		if b.wait == null or b.is_dead():
			continue
		list.append({
			"battler": b,
			"ratio": b.wait.get_ratio(),
			"eta": _eta(b),
			"ally": b == chef,
			"boss": b == boss,
			"stunned": b.wait.is_stunned(),
			"acting": b == acting,
			"deciding": b == chef and deciding,
			"order": 0,
		})
	var sorted: Array[Dictionary] = list.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["acting"] != b["acting"]:
			return a["acting"]
		return a["eta"] < b["eta"])
	var n: int = 0
	for entry in sorted:
		if is_inf(entry["eta"]) and not entry["acting"]:
			continue
		n += 1
		entry["order"] = n
	return list


## Segundos (do relógio da luta) até `b` poder agir. INF = não vai agir (Rainha voando).
func _eta(b: Battler) -> float:
	if b == acting:
		return 0.0
	if b == boss and boss.airborne and not boss.acts_while_flying():
		return INF
	var w: BattleWaitComponent = b.wait
	var speed: float = maxf(w.speed_scale * attack_speed, 0.001)
	var left: float = maxf(w.current_wait - w.elapsed, 0.0) / speed
	return w.stun_left / attack_speed + left


## DESCANSO: conta o tempo de verdade (inclusive enquanto as formigas atacam) em que o
## chef PODE atacar (barra cheia) e não escolheu nada: ele ganha mana aos poucos
## (ChefBattler.rest_mana_per_minute).
func _process(delta: float) -> void:
	if running and not _chef_acting and chef and not chef.is_dead() \
			and chef.wait.is_ready() and _queued_skill == null:
		chef.tick_rest(delta)


func stop() -> void:
	if running:
		Engine.time_scale = _saved_time_scale
	running = false
	deciding = false
	acting = null
	target = null
	_update_target_outline()
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


## Vivas que podem ser alvo agora (a Rainha protegida fica de fora).
func targetable_ants() -> Array[FormigaBattler]:
	var list: Array[FormigaBattler] = []
	for ant in alive_ants():
		if ant.can_be_targeted():
			list.append(ant)
	return list


## Formigas pequenas vivas (sem o chefe).
func alive_minions() -> Array[FormigaBattler]:
	var alive: Array[FormigaBattler] = []
	for ant in alive_ants():
		if not ant.is_boss:
			alive.append(ant)
	return alive


func is_boss_airborne() -> bool:
	return boss != null and not boss.is_dead() and boss.airborne


## Multiplicador de dano de quem ataca (pequenas em fúria com a Rainha voando).
func damage_multiplier(ant: FormigaBattler) -> int:
	if ant != null and not ant.is_boss and is_boss_airborne():
		return rage_multiplier
	return 1


# --- Formigas pequenas: vagas e invocação -------------------------------------------

func slot_positions() -> Array[Vector2]:
	var slots: Array[Vector2] = []
	if formation:
		for child in formation.get_children():
			if child is Node2D:
				slots.append((child as Node2D).global_position)
	return slots


## Vagas sem formiga pequena viva.
func free_slots() -> Array[int]:
	var taken: Array[int] = []
	for ant in alive_minions():
		taken.append(ant.slot_index)
	var free: Array[int] = []
	for i in slot_positions().size():
		if not taken.has(i):
			free.append(i)
	return free


## Cria uma formiga pequena na vaga `slot` (escondida; quem chama faz a entrada) e já
## coloca na luta. Retorna null se não houver cena/vaga.
## `scene` = outro tipo de formiga (ex.: Guardiã); vazio = `ant_scene`.
func spawn_minion(slot: int, scene: PackedScene = null) -> FormigaBattler:
	var slots: Array[Vector2] = slot_positions()
	var which: PackedScene = scene if scene else ant_scene
	if which == null or slot < 0 or slot >= slots.size():
		return null
	var ant := which.instantiate() as FormigaBattler
	ant.slot_index = slot
	(arena if arena else shake_target).add_child(ant)
	ant.global_position = slots[slot]
	ant.home_position = slots[slot]
	register_ant(ant)
	return ant


# --- Alvo --------------------------------------------------------------------------

func select_target(ant: FormigaBattler) -> void:
	if ant != null and ant.is_dead():
		ant = null
	if ant != null and not ant.can_be_targeted():
		# Clicou na Rainha protegida: avisa e mira a primeira Guardiã.
		if ant.is_protected():
			announce("A Rainha está protegida! Derrube as Guardiãs.", Color(0.6, 1.0, 1.0))
		ant = _first_alive()
	target = ant
	_update_target_outline()
	if target_cursor:
		target_cursor.follow(target, target.head_offset + Vector2(0, -14) if target else Vector2.ZERO)
	if menu:
		menu.set_target(target)
	target_changed.emit(target)


## Próximo/anterior alvo vivo (de cima para baixo, da frente para trás).
func cycle_target(step: int) -> void:
	var alive: Array[FormigaBattler] = targetable_ants()
	if alive.is_empty():
		return
	alive.sort_custom(func(a: FormigaBattler, b: FormigaBattler) -> bool:
		return a.home_position.x < b.home_position.x if not is_equal_approx(a.home_position.x, b.home_position.x) \
			else a.home_position.y < b.home_position.y)
	var index: int = alive.find(target)
	index = 0 if index < 0 else wrapi(index + step, 0, alive.size())
	select_target(alive[index])


## Aura branca na formiga da mira (tira da anterior).
func _update_target_outline() -> void:
	if _outline_tween:
		_outline_tween.kill()
		_outline_tween = null
	if is_instance_valid(_outlined) and _outlined.sprite:
		SpriteOutline.hide_on(_outlined.sprite)
	_outlined = target
	if target == null or target.sprite == null:
		return
	var outline: SpriteOutline = SpriteOutline.show_on(target.sprite, target_outline_color, target_outline_width)
	if outline:
		var dim := Color(target_outline_color, target_outline_color.a * 0.45)
		# Tween preso no próprio contorno: some junto se a formiga for apagada.
		_outline_tween = outline.create_tween().set_loops()
		_outline_tween.tween_property(outline, "color", dim, 0.45)
		_outline_tween.tween_property(outline, "color", target_outline_color, 0.45)


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


## CANALIZAÇÃO: durante `seconds` do relógio, SÓ O CHEF age (as formigas esperam).
## Termina antes se `done.call()` der true. Usado pelo Ultra Arremesso da Rainha.
## `on_tick(segundos_restantes)` é chamado a cada quadro (para atualizar avisos).
func channel(seconds: float, done: Callable, on_tick: Callable = Callable()) -> void:
	_channeling = true
	menu.lock(false)
	if chef.wait.is_ready():
		menu.set_ready(true)
	var left: float = seconds
	while left > 0.0 and running and not chef.is_dead():
		if done.call():
			break
		if await _try_chef_turn():
			menu.lock(false)
			continue
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		left -= delta
		if not chef.wait.is_ready():
			chef.wait.tick(delta * attack_speed)
			if chef.wait.is_ready():
				menu.set_ready(true)
		if on_tick.is_valid():
			on_tick.call(maxf(left, 0.0))
	menu.lock(true)
	_channeling = false


## Coloca o drop de uma formiga caída na pilha (vai para a farofa no fim).
func store_drop(ant: FormigaBattler) -> void:
	if ant.drop == null or drop_pile == null:
		return
	var drop: Sprite2D = ant.drop
	var at: Vector2 = drop.global_position
	drop.reparent(arena if arena else shake_target, false)
	drop.global_position = at
	ant.drop = null
	var to: Vector2 = drop_pile.global_position + drop_pile_spacing * drops.size()
	drops.append(drop)
	drop.z_index = 2
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(drop):
			drop.global_position = at.lerp(to, t) + Vector2(0, -50.0 * sin(PI * t)), 0.0, 1.0, 0.55)
	tween.tween_property(drop, "scale", Vector2(1.2, 1.2), 0.55)


# --- Fluxo -----------------------------------------------------------------------

func _is_won() -> bool:
	if boss:
		return boss.is_dead()
	return alive_ants().is_empty()


func _tick(delta: float) -> void:
	var menu_waiting: bool = chef.wait.is_ready() and _queued_skill == null
	if not chef.wait.is_ready():
		chef.wait.tick(delta)
		if chef.wait.is_ready():
			menu.set_ready(true)
	if menu_waiting and not active_time:
		return  # modo "espera": o tempo para enquanto o jogador escolhe
	for ant in alive_ants():
		if ant == boss and boss.airborne:
			boss.tick_flight(delta)
			if not boss.acts_while_flying():
				continue  # no céu a Rainha não ataca: só conta o voo (fora da fase final)
		ant.wait.tick(delta)


## Executa a habilidade agendada se a barra do chef estiver cheia. Retorna se agiu.
func _try_chef_turn() -> bool:
	if not chef.wait.is_ready() or _queued_skill == null:
		return false
	var skill: BattleSkill = _queued_skill
	_queued_skill = null
	menu.set_queued(null)
	if not skill.can_use(chef, target):
		menu.show_reason(skill)
		return false
	await _chef_turn(skill)
	return true


func _next_interrupting_ant() -> FormigaBattler:
	for ant in alive_ants():
		if ant.interrupting_skill(self) != null:
			return ant
	return null


func _next_ready_ant() -> FormigaBattler:
	var best: FormigaBattler = null
	for ant in alive_ants():
		if ant == boss and boss.airborne and not boss.acts_while_flying():
			continue
		if ant.wait.is_ready() and (best == null or ant.wait.elapsed - ant.wait.current_wait \
				> best.wait.elapsed - best.wait.current_wait):
			best = ant
	return best


func _on_skill_chosen(skill: BattleSkill) -> void:
	_queued_skill = skill
	menu.set_queued(skill)


func _on_boss_protection_changed(protected: bool) -> void:
	if protected:
		announce("As Guardiãs protegem a Rainha! Derrube elas primeiro!", Color(0.6, 1.0, 1.0))
		if target == boss:
			select_target(_first_alive())
	else:
		announce("A bolha estourou! A Rainha está vulnerável!", Color(0.55, 1.0, 0.55))


func _on_boss_flight_changed(airborne: bool) -> void:
	for ant in alive_minions():
		ant.set_enraged(airborne)
	if airborne:
		announce("A Rainha voou! As formigas estão em FÚRIA!", Color(1.0, 0.45, 0.4))


func _chef_turn(skill: BattleSkill) -> void:
	_busy = true
	deciding = false
	menu.set_countdown(-1.0)
	menu.lock(true)
	var aimed: FormigaBattler = target
	chef.reset_rest()
	_chef_acting = true
	acting = chef
	await skill.execute(self, chef, aimed)
	acting = null
	_chef_acting = false
	chef.wait.consume()
	menu.set_ready(false)
	await _reap_dead()
	await wait(action_pause)
	if not _channeling:
		menu.lock(false)
	_busy = false


## Turno de uma formiga. `forced` = habilidade de prioridade máxima (não sorteia).
func _ant_turn(ant: FormigaBattler, forced: FormigaSkill = null) -> void:
	_busy = true
	if deciding:
		# Ataque de prioridade máxima no meio da vez do chef: a contagem recomeça depois.
		deciding = false
		menu.set_countdown(-1.0)
	menu.lock(true)
	var attack: FormigaSkill = ant.use_skill(forced) if forced else ant.choose_skill(self)
	if attack == null:
		ant.wait.consume()
		menu.lock(false)
		_busy = false
		return
	acting = ant
	ant.show_alert(true)
	await wait(alert_time)
	ant.show_alert(false)
	if not ant.is_dead() and not chef.is_dead():
		await attack.execute(self, ant, chef)
	acting = null
	if is_instance_valid(ant) and not ant.is_dead():
		ant.wait.consume()
	await _reap_dead()
	await wait(action_pause)
	menu.lock(false)
	_busy = false


## Formigas que caíram durante a ação: animação de nocaute + drop na pilha.
func _reap_dead() -> void:
	for ant in ants:
		if not is_instance_valid(ant) or not ant.is_dead() or defeated.has(ant):
			continue
		var index: int = defeated.size()
		defeated.append(ant)
		if ant == boss and boss.airborne:
			await boss.land(true)
		if ant.devoured:
			ant.global_position = ant.home_position
		elif not ant.eaten:
			announce("%s nocauteada!" % ant.display_name, Color(0.55, 1.0, 0.55))
		await ant.play_death()
		if not ant.is_boss:
			store_drop(ant)
		ant_defeated.emit(ant, index)
	if running and (target == null or target.is_dead()):
		select_target(_first_alive())


func _first_alive() -> FormigaBattler:
	var alive: Array[FormigaBattler] = targetable_ants()
	if alive.is_empty():
		return null
	alive.sort_custom(func(a: FormigaBattler, b: FormigaBattler) -> bool:
		return a.global_position.x < b.global_position.x)
	return alive[0]


func _end(victory: bool) -> bool:
	stop()
	chef.show_wait_bar(false)
	if boss_bar:
		boss_bar.set_status("")
	if victory:
		await _reap_dead()
		# Sem a Rainha, as pequenas fogem.
		for ant in alive_minions():
			ant.set_enraged(false)
			ant.set_targetable(false)
			if ant.hp_bar:
				ant.hp_bar.set_bar_visible(false)
			ant.face(ant.global_position + Vector2(100, 0), ant.art_faces_left)
			var run := ant.create_tween()
			run.tween_property(ant, "global_position:x", 760.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			run.tween_callback(ant.queue_free)
		if not alive_minions().is_empty():
			announce("As formigas fugiram!", Color(0.55, 1.0, 0.55))
			await wait(0.9)
	else:
		announce("O chef desmaiou...", Color(1.0, 0.4, 0.4))
	battle_finished.emit(victory)
	return victory
