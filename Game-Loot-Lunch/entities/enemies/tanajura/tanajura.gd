extends Enemy

class_name tanajura


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

@onready var formigueiro: Formigueiro = get_parent() if get_tree().current_scene.has_node("Formigueiro") else null
@onready var territory: Area2D = $Territory



func _ready() -> void:
	states_timer = Timer.new()
	states_timer.one_shot = true
	add_child(states_timer)


func _process(_delta: float) -> void:
	if movement_component.mov_direction.x < 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif movement_component.mov_direction.x > 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
	
	hitbox_component.knockback_direction = velocity.normalized()


func damage_taken_animation() -> void:
	if tween and !tween.is_running:
		return
	
	tween = create_tween()
	hitbox_component.collision_shape.disabled = true
	
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0, 0.1)
		tween.tween_property(self, "modulate:a", 1, 0.1)
		
	await tween.finished
	hitbox_component.collision_shape.disabled = false


func idle_state() -> void:
	states_timer.stop()
	states_timer.wait_time = idle_time
	states_timer.start()

func alert_state() -> void:
	states_timer.stop()
	states_timer.wait_time = alert_time
	states_timer.start()


func hidden_move() -> void:
	if !formigueiro == null:
		angle = randf_range(0.0, TAU)
		radius = randf_range(0, formigueiro.collision_shape_2d.shape.radius)
		
		position += Vector2(cos(angle), sin(angle)) * radius


func _on_territory_body_entered(body: Node2D) -> void:
	if !state_machine.states["chase"] == state_machine.state:
		targets.append(body)
		state_machine.set_state(state_machine.states.alert)


func _on_territory_body_exited(body: Node2D) -> void:
	if !state_machine.states["chase"] == state_machine.state:
		targets.erase(body)
