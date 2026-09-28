extends Node2D


@onready var flame_event: FlameRandomEvent = $Churrasqueira/FlameRandomEvent
@onready var grease_event: GreaseRandomEvent = $GreaseRandomEvent


func _ready() -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		flame_event.trigger_random_event(true)
		grease_event.trigger_random_event(true)


func _draw() -> void:
	var spawn_area: Rect2 = Rect2(
		grease_event.position + grease_event.spawn_area.position,
		grease_event.spawn_area.size
	)
	draw_rect(Rect2(32, 40, 576, 280), Color("#302b32"))
	draw_rect(Rect2(32, 40, 576, 280), Color("#17171b"), false, 4.0)
	draw_rect(spawn_area, Color("#d7442e", 0.12))
	draw_rect(spawn_area, Color("#d7442e", 0.8), false, 2.0)
