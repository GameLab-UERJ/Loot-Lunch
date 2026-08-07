extends Enemy
class_name Tanajura


@export var idle_time: float = 5.0
@export var alert_time: float = 1.0
@export_range (3.0, 5.0, 0.1, "or_greater", "hide_slider" ) var hidden_time_max: float


var tween: Tween
var angle: float
var radius: float
var states_timer: Timer
var states_timer_pause: bool = false
var alert : bool = false


@onready var movement_component: MovementComponent = $MovementComponent
@onready var chase_component: ChaseComponent = $ChaseComponent
@onready var flip_sprite_component: FlipSpriteComponent = $FlipSpriteComponent
@onready var drop_component: DropComponent = $DropComponent
@onready var formigueiro: Spawn
@onready var territory: Area2D = $Territory
@onready var state_machine: Node = $FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	flip_sprite_component.originally_looks_right = false
	
	states_timer = Timer.new()
	states_timer.one_shot = true
	add_child(states_timer)
	
	formigueiro = get_parent()


func damage_taken_animation() -> void:
	if tween and !tween.is_running:
		return
	
	tween = create_tween()
	
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0, 0.1)
		tween.tween_property(self, "modulate:a", 1, 0.1)


func idle_state() -> void:
	states_timer.start(idle_time)


func alert_state() -> void:
	states_timer.start(alert_time)


func hidden_state() -> void:
	states_timer.start(randf_range(2.0, hidden_time_max))


func dead_state() -> void:
	drop_component.drop_items()
	flip_sprite_component.disable()
	formigueiro.creature_counter -= 1


func hidden_move() -> void:
	if formigueiro:
		angle = randf_range(0.0, TAU)
		radius = randi_range(formigueiro.entrance.shape.radius, formigueiro.collision_shape.shape.radius)
		position = Vector2(cos(angle), sin(angle)) * radius


func _on_territory_body_entered(_body: Node2D) -> void:
	if !state_machine.states["chase"] == state_machine.state:
		alert = true
		flip_sprite_component.node_to_face = chase_component.chased_node
	else:
		alert = true


func _on_territory_body_exited(_body: Node2D) -> void:
	alert = false
	
	if !state_machine.states["chase"] == state_machine.state:
		flip_sprite_component.node_to_face = null
	else:
		states_timer.start(5)


func _on_chase_component_next_chase_point_set(next_point: Vector2) -> void:
		if !player:
			return
		
		if !player.is_invincible:
			movement_component.move(next_point)


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	state_machine.set_state(state_machine.states.dead)


func _on_chase_component_there_is_no_player() -> void:
	alert = false
	state_machine.set_state(state_machine.states.idle)
