extends Area2D
class_name FlameTrap
## CHAMA da armadilha: alerta piscando -> chama ativa (hitbox ligada) -> apaga -> recarga.
##
## Correções de 23/10/2026:
##   - os timers respeitam a PAUSA (antes `create_timer` rodava com o jogo pausado e a
##     chama queimava os espetinhos durante o tutorial / menu de pausa);
##   - `punishment_requested` declara o parâmetro `body` que ele envia;
##   - `punishment_callback` deixou de ser @export (Callable não é editável no Inspector);
##   - se quem criou a chama apagar ela ao terminar (`deactivated`), a sequência para ali.


signal warning_started
signal activated
signal deactivated
signal punishment_requested(body: Node2D)


@export var warning_duration: float = 1.5
@export var active_duration: float = 1.0
@export var cooldown: float = 3.0

## Chamado com o corpo que encostou na chama ativa. Use `set_punishment_callback`.
var punishment_callback: Callable

var _is_active: bool = false
var _is_on_cooldown: bool = false
var _warning_tween: Tween
var _warning_scale: Vector2

@onready var warning_sprite: AnimatedSprite2D = $WarningSprite
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite
@onready var hitbox: CollisionShape2D = $Hitbox


func _ready() -> void:
	_warning_scale = warning_sprite.scale
	_set_visual_state(false, false)


func trigger() -> void:
	if _is_active or _is_on_cooldown:
		return
	_run_trigger_sequence()


func is_running() -> bool:
	return _is_active or _is_on_cooldown


func set_punishment_callback(callback: Callable) -> void:
	punishment_callback = callback


func _run_trigger_sequence() -> void:
	_is_active = true
	warning_started.emit()
	_set_visual_state(true, false)
	_warning_tween = create_tween().set_loops()
	_warning_tween.tween_property(warning_sprite, "modulate:a", 0.25, 0.18)
	_warning_tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.18)
	_warning_tween.parallel().tween_property(
		warning_sprite, "scale", _warning_scale * 1.12, 0.18
	)
	_warning_tween.tween_property(warning_sprite, "scale", _warning_scale, 0.18)

	if not await _wait(warning_duration):
		return
	activated.emit()
	_set_visual_state(false, true)

	if not await _wait(active_duration):
		return
	_set_visual_state(false, false)
	_is_active = false
	_is_on_cooldown = true
	deactivated.emit()
	if is_queued_for_deletion():
		return  # quem criou a chama já apagou ela (FlameRandomEvent)

	if not await _wait(cooldown):
		return
	_is_on_cooldown = false


## Espera `seconds` respeitando a pausa. Retorna false se a chama saiu da árvore.
func _wait(seconds: float) -> bool:
	if seconds > 0.0:
		# process_always = false: o tempo NÃO anda com o jogo pausado.
		await get_tree().create_timer(seconds, false).timeout
	return is_inside_tree() and not is_queued_for_deletion()


func _on_body_entered(body: Node2D) -> void:
	if not _is_active or not flame_sprite.visible:
		return
	punishment_requested.emit(body)
	if punishment_callback.is_valid():
		punishment_callback.call(body)


func _set_visual_state(show_warning: bool, show_flame: bool) -> void:
	if not show_warning and _warning_tween:
		_warning_tween.kill()
		_warning_tween = null
		warning_sprite.modulate.a = 1.0
		warning_sprite.scale = _warning_scale
	warning_sprite.visible = show_warning
	flame_sprite.visible = show_flame
	hitbox.set_deferred("disabled", not show_flame)
