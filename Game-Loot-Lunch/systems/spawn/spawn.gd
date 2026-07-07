extends Node2D

class_name Spawn

@export var looping: bool = true
@export var creature_scene: PackedScene
@export var spawn_time: float = 1.0
@export var spawn_limit: float = 1.0

var creature: Character
var creature_counter: float = 0.0

var timer: Timer


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_time
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


func _on_timer_timeout() -> void:
	if creature_counter < spawn_limit:
		creature = creature_scene.instantiate()

		add_child(creature)
		creature_counter += 1


func creature_died() -> void:
	if looping:
		creature_counter -= 1
