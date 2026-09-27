class_name PatienceComponent
extends Node2D

## Componente reutilizável de paciência para NPCs do restaurante.
## Gerencia uma contagem regressiva configurável e emite sinais quando
## o tempo muda ou se esgota completamente.
##
## Uso: adicione como filho de um Node2D (ex: Customer) via código ou
## na cena. Configure patience_time pelo Inspector — cada instância
## pode ter um valor diferente.

signal patience_changed(ratio: float)
signal patience_expired

@export var patience_time: float = 15.0

var time_remaining: float = 0.0

var _is_running: bool = false


func _ready() -> void:
	time_remaining = patience_time


func _process(delta: float) -> void:
	if not _is_running:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	patience_changed.emit(get_ratio())

	if time_remaining <= 0.0:
		_is_running = false
		patience_expired.emit()


func start() -> void:
	time_remaining = patience_time
	_is_running = true


func stop() -> void:
	_is_running = false
	time_remaining = patience_time


func pause() -> void:
	_is_running = false


func resume() -> void:
	if time_remaining > 0.0:
		_is_running = true


func get_ratio() -> float:
	if patience_time <= 0.0:
		return 0.0
	return clampf(time_remaining / patience_time, 0.0, 1.0)


func is_running() -> bool:
	return _is_running
