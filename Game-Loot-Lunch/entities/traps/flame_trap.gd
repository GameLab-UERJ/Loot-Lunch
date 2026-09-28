extends Area2D
class_name FlameTrap


signal warning_started
signal activated
signal deactivated
signal punishment_requested


@export var warning_duration: float = 1.5
@export var active_duration: float = 1.0
@export var cooldown: float = 3.0
@export var punishment_callback: Callable

var _is_active: bool = false
var _is_on_cooldown: bool = false
var _warning_tween: Tween

@onready var warning_sprite: AnimatedSprite2D = $WarningSprite
@onready var flame_sprite: Sprite2D = $FlameSprite
@onready var hitbox: CollisionShape2D = $Hitbox


func _ready() -> void:
	_set_visual_state(false, false)


func trigger() -> void:
	if _is_active or _is_on_cooldown:
		return
	_run_trigger_sequence()


func set_punishment_callback(callback: Callable) -> void:
	punishment_callback = callback


func _run_trigger_sequence() -> void:
	_is_active = true
	warning_started.emit()
	_set_visual_state(true, false)
	_warning_tween = create_tween().set_loops()
	_warning_tween.tween_property(warning_sprite, "modulate:a", 0.25, 0.18)
	_warning_tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(warning_duration).timeout
	if not is_inside_tree():
		return
	activated.emit()
	_set_visual_state(false, true)
	await get_tree().create_timer(active_duration).timeout
	if not is_inside_tree():
		return
	deactivated.emit()
	_set_visual_state(false, false)
	_is_active = false
	_is_on_cooldown = true
	await get_tree().create_timer(cooldown).timeout
	_is_on_cooldown = false


func _on_body_entered(body: Node2D) -> void:
	if not _is_active:
		return
	punishment_requested.emit(body)
	if punishment_callback.is_valid():
		punishment_callback.call(body)


func _set_visual_state(show_warning: bool, show_flame: bool) -> void:
	if not show_warning and _warning_tween:
		_warning_tween.kill()
		warning_sprite.modulate.a = 1.0
	warning_sprite.visible = show_warning
	flame_sprite.visible = show_flame
	hitbox.set_deferred("disabled", not show_flame)
