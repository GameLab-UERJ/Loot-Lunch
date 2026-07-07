extends Enemy
class_name Tanajura


@export var idle_time: float = 10.0
@export var alert_time: float = 3.0


var tween: Tween
var angle: float
var radius: float
var states_timer: Timer
var states_timer_pause: bool = false
var targets: Array[Node2D]


@onready var movement_component: MovementComponent = $MovementComponent
@onready var item_drop_component: ItemDropComponent = $ItemDropComponent
@onready var chase_component: ChaseComponent = $ChaseComponent
@onready var formigueiro: Spawn = get_parent() if get_tree().current_scene.has_node("Formigueiro") else null
@onready var territory: Area2D = $Territory
@onready var state_machine: Node = $FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D



func _ready() -> void:
	states_timer = Timer.new()
	states_timer.one_shot = true
	add_child(states_timer)
	chase_component.chased_node = player


func damage_taken_animation() -> void:
	if tween and !tween.is_running:
		return
	
	tween = create_tween()
	
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0, 0.1)
		tween.tween_property(self, "modulate:a", 1, 0.1)


func idle_state() -> void:
	states_timer.stop()
	states_timer.wait_time = idle_time
	states_timer.start()


func alert_state() -> void:
	states_timer.stop()
	states_timer.wait_time = alert_time
	states_timer.start()


func hidden_move() -> void:
	if formigueiro:
		angle = randf_range(0.0, TAU)
		radius = randf_range(0, formigueiro.collision_shape.shape.radius)
		
		position += Vector2(cos(angle), sin(angle)) * radius


func _on_territory_body_entered(body: Node2D) -> void:
	if !state_machine.states["chase"] == state_machine.state:
		targets.append(body)
		state_machine.set_state(state_machine.states.alert)


func _on_territory_body_exited(body: Node2D) -> void:
	if !state_machine.states["chase"] == state_machine.state:
		targets.erase(body)


func _on_chase_component_next_chase_point_set(next_point: Vector2) -> void:
	print(rad_to_deg(next_point.angle()))
	movement_component.move(next_point)


func _on_got_hurt() -> void:
	damage_taken_animation()


func _on_died() -> void:
	state_machine.set_state(state_machine.states.dead)
