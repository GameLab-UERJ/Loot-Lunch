extends RandomEvent
class_name GreaseRandomEvent
## GRAXA aleatória: mostra um alerta num ponto sorteado de `spawn_area` e, depois dele,
## cria uma poça (GreaseTrap) que some sozinha depois de `grease_lifetime` segundos.
##
## Correção de 23/10/2026: as esperas respeitam a PAUSA e a poça é apagada por um Timer
## filho dela (se a cena trocar no meio, não sobra corrotina esperando).


@export var grease_scene: PackedScene
@export var warning_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-96, -48, 192, 96)
@export var grease_lifetime: float = 8.0
@export var warning_duration: float = 1.0


func _activate_event() -> void:
	if not grease_scene:
		return
	var spawn_position := Vector2(
		_random.randf_range(spawn_area.position.x, spawn_area.end.x),
		_random.randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	if warning_scene and warning_duration > 0.0:
		var warning: TrapWarning = warning_scene.instantiate() as TrapWarning
		if warning:
			warning.position = spawn_position
			warning.visible_duration = warning_duration
			add_child(warning)
			warning.show_for(warning_duration)
		# process_always = false: o alerta não "anda" com o jogo pausado.
		await get_tree().create_timer(warning_duration, false).timeout
		if not is_inside_tree():
			return
	var grease: GreaseTrap = grease_scene.instantiate() as GreaseTrap
	if grease == null:
		return
	grease.position = spawn_position
	add_child(grease)
	if grease_lifetime > 0.0:
		var life := Timer.new()
		life.one_shot = true
		life.wait_time = grease_lifetime
		life.timeout.connect(grease.queue_free)
		grease.add_child(life)
		life.start()
