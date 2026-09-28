extends Node
class_name CooldownComponent
## Tempo de espera reutilizável: pé de cogumelo regenerando, fogão cozinhando, habilidade recarregando...
## Só conta o tempo e avisa. Quem usa decide o que fazer quando começa/termina.


signal started(duration: float)
signal finished


## Duração padrão em segundos.
@export var duration: float = 5.0
## Começa contando assim que a cena carrega.
@export var start_on_ready: bool = false


var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	if start_on_ready:
		start()


## Inicia (ou reinicia) a contagem. `custom_duration` <= 0 usa `duration`.
func start(custom_duration: float = -1.0) -> void:
	var time: float = duration if custom_duration <= 0.0 else custom_duration
	if time <= 0.0:
		finished.emit()
		return
	_timer.start(time)
	started.emit(time)


func stop() -> void:
	_timer.stop()


func is_ready() -> bool:
	return _timer.is_stopped()


func get_time_left() -> float:
	return _timer.time_left


## 0.0 = acabou de começar, 1.0 = pronto.
func get_progress() -> float:
	if is_ready() or _timer.wait_time <= 0.0:
		return 1.0
	return 1.0 - _timer.time_left / _timer.wait_time


func _on_timer_timeout() -> void:
	finished.emit()
