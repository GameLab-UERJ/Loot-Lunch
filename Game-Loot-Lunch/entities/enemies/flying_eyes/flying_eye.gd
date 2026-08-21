extends Enemy
class_name FlyingEye

@export var idle_time: float = 5.0


var states_timer: Timer
var states_timer_pause: bool = false
var alert : bool = false


@onready var wing_flap_sfx: AudioStreamPlayer2D = $WingFlapSfx
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var chase_component: ChaseComponent = $ChaseComponent
@onready var flip_sprite_component: FlipSpriteComponent = $FlipSpriteComponent
@onready var state_machine: Node = $FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var drop_component: DropComponent = $DropComponent
@onready var territory_2d: CollisionShape2D = $Territory/Territory2D
@onready var patrol_component: PatrolComponent = $PatrolComponent
@onready var parent: RetangleSpawn = get_parent() if get_parent() is RetangleSpawn else null


func _ready() -> void:
	if player:
		chase_component.chased_node = player
		flip_sprite_component.node_to_face = player
	
	states_timer = Timer.new()
	states_timer.one_shot = true
	add_child(states_timer)


func _process(_delta: float) -> void:
	hitbox_component.knockback_direction = velocity.normalized()


func _on_wing_flap() -> void:
	match animated_sprite.frame:
		2:
			wing_flap_sfx.pitch_scale = randf_range(0.9,1.1)
			wing_flap_sfx.play()


func _on_patrol_component_next_target_point_set(next_point: Vector2) -> void:
	movement_component.move(next_point)


func _on_chase_component_next_chase_point_set(next_point: Vector2) -> void:
	movement_component.move(next_point)


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	state_machine.set_state(state_machine.states.dead)


func _on_chase_component_there_is_no_player() -> void:
	state_machine.set_state(state_machine.states.idle)


func _on_territory_body_entered(_body: Node2D) -> void:
	alert = true


func _on_territory_body_exited(_body: Node2D) -> void:
	alert = false
	states_timer.start(5)


func idle_state() -> void:
	states_timer.start(idle_time)
