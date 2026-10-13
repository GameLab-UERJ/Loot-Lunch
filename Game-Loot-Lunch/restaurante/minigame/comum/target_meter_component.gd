extends Node
class_name TargetMeterComponent
## MEDIDOR de "ponto": um valor de 0 a 1 que sobe enquanto está ATIVO e que precisa
## ser parado dentro da zona perfeita. Não sabe se é carne, macaxeira ou manteiga:
## as regras vêm do TargetMeterProfile (.tres) e quem usa liga/desliga com `set_active`.
##
##   meter.set_active(true)    # segurando ESPAÇO / despejando manteiga / no fogo
##   meter.add(0.1)            # empurrão de fora (fagulha caiu na carne!)
##   meter.get_zone()          # UNDER / PERFECT / OVER
##   meter.get_quality()       # 0..1 (1 = centro exato)
##
## Reutilizável: Fase 1 (carne), Fase 2 (cozimento e manteiga), qualquer minigame de timing.
## Quem desenha é o TimingGauge (aponte o `meter` dele para este nó).


signal value_changed(value: float)
signal zone_changed(zone: TargetMeterProfile.Zone)
## Passou de `ruin_at`: estragou na hora (carbonizou, encharcou...).
signal ruined


@export var profile: TargetMeterProfile
## Começa subindo?
@export var active: bool = false
## Desligado = congelado (nem sobe nem desce). A etapa liga quando começa.
@export var running: bool = false
## Zera a aceleração cada vez que desativa. Ligado = cada "pulso" recomeça devagar
## (ex.: manteiga que engrossa enquanto segura o clique).
@export var reset_acceleration_on_stop: bool = false


## Multiplicador de velocidade aplicado por quem usa (ex.: macaxeira grudando na chapa).
## Não mexe no .tres (que pode ser compartilhado).
var speed_multiplier: float = 1.0


var value: float = 0.0
## Segundos acumulados com o medidor ativo (usado na aceleração).
var active_time: float = 0.0
var _clock: float = 0.0
var _zone: TargetMeterProfile.Zone = TargetMeterProfile.Zone.UNDER
var _ruined: bool = false


func _ready() -> void:
	if profile == null:
		profile = TargetMeterProfile.new()
		push_warning("TargetMeterComponent '%s': sem profile, usando o padrão." % name)


func _process(delta: float) -> void:
	if not running or _ruined:
		return
	_clock += delta
	if active:
		active_time += delta
		var speed: float = (profile.rise_speed + profile.rise_acceleration * active_time) * speed_multiplier
		if profile.wobble > 0.0:
			speed *= 1.0 + profile.wobble * sin(_clock * profile.wobble_frequency * TAU)
		add(maxf(speed, 0.0) * delta)
	elif profile.fall_speed > 0.0 and value > 0.0:
		add(-profile.fall_speed * delta)


func set_active(value_active: bool) -> void:
	if active and not value_active and reset_acceleration_on_stop:
		active_time = 0.0
	active = value_active


## Soma (ou tira) do valor. Retorna o valor novo.
func add(amount: float) -> float:
	if _ruined:
		return value
	value = clampf(value + amount, 0.0, 1.0)
	value_changed.emit(value)
	var zone: TargetMeterProfile.Zone = profile.zone_of(value)
	if zone != _zone:
		_zone = zone
		zone_changed.emit(zone)
	if value >= profile.ruin_at:
		_ruined = true
		ruined.emit()
	return value


func reset() -> void:
	value = 0.0
	active_time = 0.0
	_clock = 0.0
	speed_multiplier = 1.0
	_ruined = false
	_zone = TargetMeterProfile.Zone.UNDER
	value_changed.emit(value)


func get_zone() -> TargetMeterProfile.Zone:
	return profile.zone_of(value)


func is_perfect() -> bool:
	return get_zone() == TargetMeterProfile.Zone.PERFECT


func is_ruined() -> bool:
	return _ruined


## Abaixo do mínimo para "tirar do fogo" (soltar aqui é só pausa)?
func is_below_commit() -> bool:
	return value < profile.min_commit


func get_quality() -> float:
	return profile.quality_of(value)


func get_label() -> String:
	return profile.label_of(value)
