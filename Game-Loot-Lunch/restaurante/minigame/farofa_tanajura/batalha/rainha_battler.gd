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


@export var boss_title: String = "TANAJURA RAINHA"
## Asas (AnimatedSprite2D atrás do corpo) e sombra no chão quando voa.
@export var wings: AnimatedSprite2D
@export var ground_shadow: Node2D
@export_group("Voo")
## Altura do voo (px).
@export var flight_height: float = 110.0
## Segundos no céu (relógio da batalha) até descer sozinha.
@export_range(1.0, 60.0, 0.5, "suffix:s") var flight_time: float = 12.0
@export var wing_speed_ground: float = 1.0
@export var wing_speed_air: float = 3.0
## Segundos atordoada quando é derrubada pela Besta.
@export var shot_down_daze: float = 2.0
@export_group("Vida")
## Vida (0..1) em que Devorar e Conjurar sai (uma vez cada).
@export var devour_thresholds: Array[float] = [0.6, 0.2]


var airborne: bool = false
var flight_left: float = 0.0
var charging: bool = false
var charge_hits: int = 0
var _used_thresholds: Array[float] = []
var _busy_moving: bool = false


func _ready() -> void:
	super._ready()
	hit_taken.connect(_on_hit_taken)
	if ground_shadow:
		ground_shadow.top_level = true  # fica no chão enquanto ela sobe
		ground_shadow.visible = false
	_set_wing_speed(wing_speed_ground)


func is_airborne() -> bool:
	return airborne


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
	tween.tween_property(self, "global_position:y", home_position.y - flight_height, 0.6) \
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
	flight_left = maxf(flight_left - delta, 0.0)
	status_changed.emit("VOANDO %.0fs — só a Besta alcança!" % ceilf(flight_left))
	return flight_left <= 0.0


## Flechada da Besta: no ar = cai e as asas devolvem a mana toda do chef.
func on_ranged_hit(battle: Node, user: Battler) -> void:
	if not airborne or is_dead():
		return
	if battle is TurnBattle:
		(battle as TurnBattle).announce("Derrubou a Rainha! Mana cheia!", Color(0.6, 0.85, 1.0))
		(battle as TurnBattle).shake(5.0, 0.3)
	var mana: ManaComponent = ManaComponent.find_in(user)
	if mana:
		mana.restore_full()
		FloatingText.spawn(user.get_parent(), user.global_position + Vector2(0, -52), "MANA CHEIA!", Color(0.55, 0.8, 1.0))
	await land(true)


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
		var height: float = clampf((home_position.y - global_position.y) / maxf(flight_height, 1.0), 0.0, 1.0)
		ground_shadow.scale = Vector2.ONE * lerpf(1.0, 0.7, height)
