extends FormigaBattler
class_name QueenAntBattler
## A TANAJURA RAINHA: o chefe de verdade da Fase 3 (formiga gigante com asas).
##
## É uma FormigaBattler (mesma vida, espera, alerta, sorteio de habilidades), com o que
## só o chefe tem:
##   - VOAR: `fly_up()` / `land()`. No ar ela fica fora do alcance corpo a corpo
##     (`is_airborne`), a espera dela para e as formigas pequenas entram em FÚRIA
##     (a batalha dobra o dano delas). Uma flechada da Besta derruba (`on_ranged_hit`) e
##     as asas devolvem a mana TODA do chef.
##   - CARGA (Ultra Arremesso): conta os golpes que leva enquanto carrega (`charge_hits`).
##   - LIMIARES de vida (`devour_thresholds`): Devorar e Conjurar sai uma vez em cada.
##   - Status para a barra de vida do topo (`status_changed`).
##
## As habilidades ficam nos filhos (skills_rainha/ + o LancarPedra reaproveitado como
## Cortes de Vento). Nada aqui sabe o que cada uma faz.


signal status_changed(text: String)
signal flight_changed(airborne: bool)
## Entrou na FASE FINAL (Devorar e Conjurar dos 20%: Guardiãs + voo + magias).
signal final_phase_started
## Protegida pelas Guardiãs (true) / ficou vulnerável (false).
signal protection_changed(protected: bool)


@export var boss_title: String = "TANAJURA RAINHA"
## Asas (AnimatedSprite2D atrás do corpo) e sombra no chão quando voa.
@export var wings: AnimatedSprite2D
@export var ground_shadow: Node2D
@export_group("Voo")
## Altura do voo (px).
@export var flight_height: float = 110.0
## Altura do voo na FASE FINAL (mais baixa: ela fica no céu muito tempo e não pode sair
## da tela com a bolha).
@export var final_flight_height: float = 60.0
## Segundos no céu (relógio da batalha) até descer sozinha.
@export_range(1.0, 60.0, 0.5, "suffix:s") var flight_time: float = 12.0
@export var wing_speed_ground: float = 1.0
@export var wing_speed_air: float = 3.0
## Segundos atordoada quando é derrubada pela Besta.
@export var shot_down_daze: float = 2.0
@export_group("Vida")
## Vida (0..1) em que Devorar e Conjurar sai (uma vez cada).
@export var devour_thresholds: Array[float] = [0.6, 0.2]
@export_group("Fase final")
## Bolha de proteção enquanto houver Guardiã viva (raio e altura em relação à Rainha).
@export var shield_radius: float = 82.0
@export var shield_offset: Vector2 = Vector2(0, -16)
@export_group("Recompensa")
## Item que o jogador ganha ao derrotar a Rainha. O ITEM AINDA NÃO EXISTE no jogo:
## por enquanto é só o aviso + ícone (LootPopup) e o registro em "loot" no resultado da
## Fase 3. Quando o item for criado, entregue-o a partir de `loot` (ver BossFightVip).
@export var loot_id: StringName = &"asa_formiga_rainha"
@export var loot_name: String = "Asa de Formiga Rainha"
## Ícone do item. Vazio = 1º quadro das asas.
@export var loot_icon: Texture2D


var airborne: bool = false
var flight_left: float = 0.0
var charging: bool = false
var charge_hits: int = 0
var _used_thresholds: Array[float] = []
var _busy_moving: bool = false
## FASE FINAL: ataca voando (Raio Psíquico, Esferas, 10 Cortes de Vento) e fica
## protegida enquanto houver Guardiã viva.
var final_phase: bool = false
var guardians: Array[FormigaBattler] = []
var _shield: ShieldBubble = null


func _ready() -> void:
	super._ready()
	hit_taken.connect(_on_hit_taken)
	if ground_shadow:
		ground_shadow.top_level = true  # fica no chão enquanto ela sobe
		ground_shadow.visible = false
	_set_wing_speed(wing_speed_ground)


func is_airborne() -> bool:
	return airborne


# --- Fase final e Guardiãs -----------------------------------------------------------

func enter_final_phase() -> void:
	if final_phase:
		return
	final_phase = true
	phase = 1
	final_phase_started.emit()


## Na fase final ela ataca do céu (a batalha continua enchendo a espera dela no ar).
func acts_while_flying() -> bool:
	return final_phase


## Guardiã nova: enquanto houver uma viva, a Rainha fica na bolha.
func add_guardian(guardian: FormigaBattler) -> void:
	if guardians.has(guardian):
		return
	guardians.append(guardian)
	guardian.defeated.connect(_on_guardian_defeated)
	_refresh_protection()


func alive_guardians() -> Array[FormigaBattler]:
	var alive: Array[FormigaBattler] = []
	for g in guardians:
		if is_instance_valid(g) and not g.is_dead():
			alive.append(g)
	return alive


func is_protected() -> bool:
	return not is_dead() and not alive_guardians().is_empty()


## Protegida: o golpe não entra (a bolha pisca).
func take_hit(amount: int, from_direction: Vector2 = Vector2.ZERO) -> int:
	if is_protected():
		if _shield:
			_shield.flash()
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -60), "Protegida!", Color(0.6, 1.0, 1.0))
		return 0
	# Antes da fase final ela NÃO morre: fica com 1 de vida e o Devorar e Conjurar dos
	# 20% sai em seguida (nenhum combo pula a fase final).
	if not final_phase and not devour_thresholds.is_empty() \
			and not _used_thresholds.has(devour_thresholds.min()) and health:
		amount = mini(amount, health.hp - 1)
		if amount <= 0:
			FloatingText.spawn(get_parent(), global_position + Vector2(0, -60), "Resiste!", Color(1.0, 0.6, 0.5))
			return 0
	return super.take_hit(amount, from_direction)


func _on_guardian_defeated(_ant: FormigaBattler) -> void:
	_refresh_protection()


func _refresh_protection() -> void:
	var alive: Array[FormigaBattler] = alive_guardians()
	if not alive.is_empty():
		if _shield == null:
			_shield = ShieldBubble.new()
			_shield.radius = shield_radius
			_shield.z_index = 4
			add_child(_shield)
			_shield.position = shield_offset
			set_targetable(false)
			protection_changed.emit(true)
		_shield.links.assign(alive)
		status_changed.emit("PROTEGIDA pelas Guardiãs (%d)" % alive.size())
		return
	if _shield:
		_shield.pop()
		_shield = null
		set_targetable(true)
		# Sem as Guardiãs o relógio do voo volta a contar: ela desce sozinha depois.
		if airborne:
			flight_left = flight_time
		status_changed.emit("")
		protection_changed.emit(false)


# --- Voo -----------------------------------------------------------------------------

func fly_up() -> void:
	if airborne:
		return
	airborne = true
	flight_left = flight_time
	_set_wing_speed(wing_speed_air)
	if hp_bar:
		hp_bar.set_bar_visible(false)
	_show_shadow(true)
	var tween := create_tween()
	var height: float = final_flight_height if final_phase else flight_height
	tween.tween_property(self, "global_position:y", home_position.y - height, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	flight_changed.emit(true)
	status_changed.emit("VOANDO — só a Besta alcança!")


## Desce. `crash` = caiu com a flechada (desce rápido e fica tonta).
func land(crash: bool = false) -> void:
	if not airborne:
		return
	airborne = false
	flight_left = 0.0
	flight_changed.emit(false)
	status_changed.emit("")
	_set_wing_speed(wing_speed_ground)
	var tween := create_tween()
	if crash:
		tween.tween_property(self, "global_position:y", home_position.y, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(self, "global_position:y", home_position.y, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	global_position = home_position
	_show_shadow(false)
	if crash:
		squash(Vector2(1.25, 0.75), 0.3)
		daze(shot_down_daze)


## A batalha chama a cada quadro em que o relógio anda. Retorna true quando o tempo
## de voo acabou (a batalha manda ela descer num momento seguro).
func tick_flight(delta: float) -> bool:
	if not airborne:
		return false
	if is_protected():
		# Com Guardiãs vivas ela fica no céu o tempo que quiser.
		status_changed.emit("VOANDO e PROTEGIDA pelas Guardiãs (%d)" % alive_guardians().size())
		return false
	flight_left = maxf(flight_left - delta, 0.0)
	status_changed.emit("VOANDO %.0fs — só a Besta alcança!" % ceilf(flight_left))
	return flight_left <= 0.0


## Flechada da Besta: no ar = cai e as asas devolvem a mana toda do chef.
func on_ranged_hit(battle: Node, user: Battler) -> void:
	if not airborne or is_dead() or is_protected():
		return
	if battle is TurnBattle:
		(battle as TurnBattle).announce("Derrubou a Rainha! Mana cheia!", Color(0.6, 0.85, 1.0))
		(battle as TurnBattle).shake(5.0, 0.3)
	var mana: ManaComponent = ManaComponent.find_in(user)
	if mana:
		mana.restore_full()
		FloatingText.spawn(user.get_parent(), user.global_position + Vector2(0, -52), "MANA CHEIA!", Color(0.55, 0.8, 1.0))
	await land(true)


# --- Morte e recompensa -------------------------------------------------------------

## Nocaute da Rainha: as asas param, caem e somem junto com o corpo; a sombra some.
func play_death() -> void:
	_show_shadow(false)
	if _shield:
		_shield.pop()
		_shield = null
	if wings:
		wings.speed_scale = 0.0
		var fall := create_tween().set_parallel(true)
		fall.tween_property(wings, "position:y", wings.position.y + 30.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_property(wings, "rotation", deg_to_rad(25.0), 0.45)
		fall.tween_property(wings, "modulate:a", 0.0, 0.45)
		fall.chain().tween_callback(wings.hide)
	await super.play_death()
	if wings:
		wings.hide()


## Ícone da recompensa (o exportado ou o 1º quadro das asas).
func get_loot_icon() -> Texture2D:
	if loot_icon:
		return loot_icon
	if wings and wings.sprite_frames and wings.sprite_frames.get_animation_names().size() > 0:
		var anim: StringName = wings.sprite_frames.get_animation_names()[0]
		return wings.sprite_frames.get_frame_texture(anim, 0)
	return null


## Dados da recompensa para o resultado da etapa.
func get_loot() -> Dictionary:
	return {"id": loot_id, "name": loot_name}


# --- Carga (Ultra Arremesso) ----------------------------------------------------------

func begin_charge() -> void:
	charging = true
	charge_hits = 0


func end_charge() -> void:
	charging = false


# --- Limiares de vida ----------------------------------------------------------------

## Próximo limiar atingido e ainda não usado (-1 = nenhum).
func pending_threshold() -> float:
	var ratio: float = health.get_ratio()
	for t in devour_thresholds:
		if ratio <= t and not _used_thresholds.has(t):
			return t
	return -1.0


## Marca como usados todos os limiares já atingidos (cair de 70% para 15% num golpe
## gasta os dois de uma vez: a magia sai uma vez só).
func consume_thresholds() -> void:
	var ratio: float = health.get_ratio()
	for t in devour_thresholds:
		if ratio <= t and not _used_thresholds.has(t):
			_used_thresholds.append(t)


# --- Internos ------------------------------------------------------------------------

func _on_hit_taken(_amount: int) -> void:
	if charging:
		charge_hits += 1


func _set_wing_speed(value: float) -> void:
	if wings:
		wings.speed_scale = value


func _show_shadow(value: bool) -> void:
	if ground_shadow == null:
		return
	ground_shadow.visible = value
	ground_shadow.global_position = home_position + Vector2(0, ground_offset)


func _process(_delta: float) -> void:
	if ground_shadow and ground_shadow.visible:
		ground_shadow.global_position = Vector2(global_position.x, home_position.y + ground_offset)
		var top: float = final_flight_height if final_phase else flight_height
		var height: float = clampf((home_position.y - global_position.y) / maxf(top, 1.0), 0.0, 1.0)
		ground_shadow.scale = Vector2.ONE * lerpf(1.0, 0.7, height)
