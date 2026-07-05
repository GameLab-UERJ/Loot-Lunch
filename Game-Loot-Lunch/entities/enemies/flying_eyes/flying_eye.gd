extends Enemy
class_name FlyingEye


@onready var wing_flap_sfx: AudioStreamPlayer2D = $WingFlapSfx
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var chase_component: ChaseComponent = $ChaseComponent
@onready var flip_sprite_component: FlipSpriteComponent = $FlipSpriteComponent
@onready var state_machine: Node = $FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if player:
		flip_sprite_component.node_to_face = player
		chase_component.chased_node = player


func _process(_delta: float) -> void:
	hitbox_component.knockback_direction = velocity.normalized()


func _on_wing_flap() -> void:
	match animated_sprite.frame:
		2:
			wing_flap_sfx.pitch_scale = randf_range(0.9,1.1)
			wing_flap_sfx.play()


func _on_chase_component_next_chase_point_set(next_point: Vector2) -> void:
	movement_component.move(next_point)


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	state_machine.set_state(state_machine.states.dead)


func _on_chase_component_there_is_no_player() -> void:
	state_machine.set_state(state_machine.states.idle)
