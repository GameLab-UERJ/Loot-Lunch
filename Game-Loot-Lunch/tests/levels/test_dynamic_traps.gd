extends Node2D


@onready var event_manager: RandomEventManager = $RandomEventManager


func _ready() -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		event_manager.trigger_random_event()


func _draw() -> void:
	var spawn_area: Rect2 = Rect2(
		event_manager.position + event_manager.grease_spawn_area.position,
		event_manager.grease_spawn_area.size
	)
	draw_rect(Rect2(32, 40, 576, 280), Color("#302b32"))
	draw_rect(Rect2(32, 40, 576, 280), Color("#17171b"), false, 4.0)
	draw_rect(spawn_area, Color("#d7442e", 0.12))
	draw_rect(spawn_area, Color("#d7442e", 0.8), false, 2.0)
	draw_rect(Rect2(event_manager.position - Vector2(42, 18), Vector2(84, 36)), Color("#261d25"))
	draw_rect(Rect2(event_manager.position - Vector2(34, 10), Vector2(68, 28)), Color("#5a3b32"))
	draw_rect(Rect2(event_manager.position - Vector2(28, 5), Vector2(56, 8)), Color("#17171b"))
	draw_line(
		event_manager.position + Vector2(-24, 2),
		event_manager.position + Vector2(24, 2),
		Color("#d7442e"),
		3.0
	)
