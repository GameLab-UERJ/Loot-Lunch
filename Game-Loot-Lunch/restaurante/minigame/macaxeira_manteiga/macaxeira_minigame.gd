extends BossMinigame
class_name MacaxeiraMinigame
## FASE 2 da boss fight do VIP: MACAXEIRA NA MANTEIGA DE GARRAFA ("Alquimia de Cozimento").
##
## Duas coisas ao MESMO TEMPO (o olho tem que ir e voltar):
##   1. COZIMENTO (barra vertical): a macaxeira cozinha sozinha na chapa, num ritmo
##      irregular. Aperte ESPAÇO para TIRAR da chapa quando estiver na faixa dourada.
##   2. MANTEIGA (barra horizontal): a garrafa segue o MOUSE. SEGURE o clique para
##      inclinar e despejar. Só conta a manteiga que cai EM CIMA da macaxeira; o fluxo
##      engrossa quanto mais tempo segura (solte em pulsos para dosar).
##
## Sem manteiga a macaxeira gruda e cozinha mais rápido (`dry_cook_multiplier`) — não dá
## para deixar a garrafa de lado. Manteiga demais = encharcada na hora.
##
## Resultado (ao apertar ESPAÇO):
##   cozimento antes da faixa = "Macaxeira Crua"    | depois = "Macaxeira Queimada"
##   manteiga  antes da faixa = "Macaxeira Seca"    | depois = "Macaxeira Encharcada"
##   as duas na faixa         = "Macaxeira na Manteiga Perfeita"


## Quadros de macaxeira_estados.png.
enum Look { CRUA, DOURADA, QUEIMADA, ENCHARCADA }


@export var serve_action: StringName = &"chef_pick_drop"
@export var cook_meter: TargetMeterComponent
@export var butter_meter: TargetMeterComponent
@export var bottle: GarrafaManteiga
## Sprite da macaxeira (macaxeira_estados.png com hframes = 4).
@export var macaxeira: Sprite2D

@export_group("Regras")
## Meia-largura (px) em cima da macaxeira onde a manteiga conta.
@export var catch_half_width: float = 34.0
## Abaixo disto de manteiga a macaxeira está "seca" e gruda...
@export_range(0.0, 1.0, 0.01) var dry_butter_level: float = 0.25
## ...e a partir deste cozimento ela começa a grudar (cozinha mais rápido).
@export_range(0.0, 1.0, 0.01) var dry_from_cook: float = 0.35
@export var dry_cook_multiplier: float = 1.7
## Manteiga que cai na chapa (fora da macaxeira) faz a chapa esfumaçar e ESQUENTA o
## cozimento um tiquinho por segundo.
@export_range(0.0, 0.2, 0.005) var spill_heat_per_second: float = 0.03


var _spill_timer: float = 0.0
var _dry_warned: bool = false


func _ready() -> void:
	super._ready()
	cook_meter.ruined.connect(_on_cook_ruined)
	butter_meter.ruined.connect(_on_butter_ruined)
	_update_look()


func _on_begin() -> void:
	cook_meter.reset()
	butter_meter.reset()
	cook_meter.running = true
	cook_meter.set_active(true)
	butter_meter.running = true
	bottle.set_enabled(true)
	popup(macaxeira.global_position + Vector2(0, -40), "Na chapa!", Color(1.0, 0.85, 0.4))


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not running:
		return
	if event.is_action_pressed(serve_action) and not event.is_echo():
		get_viewport().set_input_as_handled()
		if cook_meter.is_below_commit():
			popup(macaxeira.global_position + Vector2(0, -30), "Ainda crua!", Color(0.8, 0.85, 1.0))
			return
		_serve()


func _process(delta: float) -> void:
	if not running:
		return
	var flowing: bool = bottle.is_flowing()
	var on_target: bool = absf(bottle.get_stream_x() - macaxeira.global_position.x) <= catch_half_width
	butter_meter.set_active(flowing and on_target)

	if flowing and not on_target:
		cook_meter.add(spill_heat_per_second * delta)
		_spill_timer -= delta
		if _spill_timer <= 0.0:
			_spill_timer = 0.7
			popup(Vector2(bottle.get_stream_x(), bottle.stream_floor_y - 8.0), "Na chapa não!",
				Color(1.0, 0.7, 0.4))

	# Seca: gruda e acelera o cozimento (o "dourar por fora" precisa da manteiga).
	var dry: bool = butter_meter.value < dry_butter_level and cook_meter.value >= dry_from_cook
	cook_meter.speed_multiplier = dry_cook_multiplier if dry else 1.0
	if dry and not _dry_warned:
		_dry_warned = true
		popup(macaxeira.global_position + Vector2(0, -34), "Grudando! Manteiga!", Color(1.0, 0.5, 0.35))
	elif not dry:
		_dry_warned = false
	_update_look()


func _serve() -> void:
	var cook_zone: TargetMeterProfile.Zone = cook_meter.get_zone()
	var butter_zone: TargetMeterProfile.Zone = butter_meter.get_zone()
	if cook_zone != TargetMeterProfile.Zone.PERFECT:
		_end(false, cook_meter.get_label(), 0.0)
	elif butter_zone != TargetMeterProfile.Zone.PERFECT:
		_end(false, butter_meter.get_label(), 0.0)
	else:
		var quality: float = (cook_meter.get_quality() + butter_meter.get_quality()) * 0.5
		_end(true, cook_meter.profile.perfect_label, quality)


func _end(success: bool, label: String, quality: float) -> void:
	_update_look()
	popup(macaxeira.global_position + Vector2(0, -36), label,
		Color(0.55, 1.0, 0.55) if success else Color(1.0, 0.45, 0.45))
	finish(success, {
		"label": label,
		"quality": quality,
		"stars": BossMinigame.stars_for(quality) if success else 0,
		"cook": cook_meter.value,
		"butter": butter_meter.value,
	})


func _on_finish(_success: bool) -> void:
	cook_meter.running = false
	butter_meter.running = false
	bottle.set_enabled(false)


func _on_cook_ruined() -> void:
	if running:
		_end(false, cook_meter.profile.over_label, 0.0)


func _on_butter_ruined() -> void:
	if running:
		_end(false, butter_meter.profile.over_label, 0.0)


func _update_look() -> void:
	if macaxeira == null:
		return
	var look: Look = Look.CRUA
	if butter_meter.get_zone() == TargetMeterProfile.Zone.OVER:
		look = Look.ENCHARCADA
	elif cook_meter.get_zone() == TargetMeterProfile.Zone.OVER:
		look = Look.QUEIMADA
	elif cook_meter.value >= cook_meter.profile.perfect_min * 0.75:
		look = Look.DOURADA
	macaxeira.frame = look
	# Brilho amanteigado conforme a dose.
	macaxeira.modulate = Color.WHITE.lerp(Color(1.12, 1.06, 0.8), butter_meter.value)
