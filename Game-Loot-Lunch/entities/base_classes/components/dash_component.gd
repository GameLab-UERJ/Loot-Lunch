extends Node
class_name DashComponent
## Dash com duração, velocidade, cooldown e invulnerabilidade opcional.
## Reutilizável em qualquer Character (chef, inimigo que investe, etc.).


signal dash_started(direction: Vector2)
signal dash_finished
signal cooldown_finished


@export var dash_speed: float = 350.0
@export var dash_duration: float = 0.18
## Tempo de espera, contado a partir do FIM do dash.
@export var cooldown: float = 0.8
@export var invulnerable_during_dash: bool = true
## Se vazio, usa o nó pai.
@export var character: Character


var is_dashing: bool = false
var _direction: Vector2 = Vector2.ZERO
var _time_left: float = 0.0
var _cooldown_left: float = 0.0
var _granted_invulnerability: bool = false


func _ready() -> void:
	if character == null:
		character = get_parent() as Character
	assert(character != null, "DashComponent precisa de um Character (pai ou export).")


func _physics_process(delta: float) -> void:
	if is_dashing:
		character.velocity = _direction * dash_speed
		_time_left -= delta
		if _time_left <= 0.0:
			_finish()
	elif _cooldown_left > 0.0:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			_cooldown_left = 0.0
			cooldown_finished.emit()


func can_dash() -> bool:
	return not is_dashing and _cooldown_left <= 0.0


func try_dash(direction: Vector2) -> bool:
	if not can_dash() or direction == Vector2.ZERO:
		return false

	is_dashing = true
	_direction = direction.normalized()
	_time_left = dash_duration
	character.velocity = _direction * dash_speed

	if invulnerable_during_dash and not character.is_invulnerable:
		character.is_invulnerable = true
		_granted_invulnerability = true

	dash_started.emit(_direction)
	return true


## Interrompe o dash (ex.: morreu). Ainda aplica o cooldown.
func cancel() -> void:
	if is_dashing:
		_finish()


## 0.0 = pronto, 1.0 = acabou de usar. Útil para HUD.
func get_cooldown_ratio() -> float:
	if cooldown <= 0.0:
		return 0.0
	return clampf(_cooldown_left / cooldown, 0.0, 1.0)


func _finish() -> void:
	is_dashing = false
	# Sai do dash com velocidade normal para não "escorregar" demais.
	character.velocity = _direction * character.max_speed
	_cooldown_left = cooldown

	if _granted_invulnerability:
		character.is_invulnerable = false
		_granted_invulnerability = false

	dash_finished.emit()
