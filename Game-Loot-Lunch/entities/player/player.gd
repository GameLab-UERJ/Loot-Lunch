extends Character
class_name Player


var can_control: bool = true


@onready var sword: Node2D = $Sword
@onready var sword_hitbox: HitboxComponent = $Sword/Node2D/Sword/HitboxComponent
@onready var sword_animation_player: AnimationPlayer = $Sword/SwordAnimationPlayer
@onready var movement_component: MovementComponent = $MovementComponent
@onready var footsteps_sfx: AudioStreamPlayer2D = $FootstepsSfx
@onready var hit_stf: AudioStreamPlayer2D = $HitStf
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var input_component: InputComponent = $InputComponent
@onready var state_machine: FiniteStateMachine = %FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	

func _process(_delta: float) -> void:
	var mouse_direction: Vector2 = global_position.direction_to(get_global_mouse_position())

	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true

	sword.rotation = mouse_direction.angle()
	sword_hitbox.knockback_direction = mouse_direction
	if sword.scale.y == 1 and mouse_direction.x < 0:
		sword.scale.y = -1
	elif sword.scale.y == -1 and mouse_direction.x > 0:
		sword.scale.y = 1


func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return

	if event.is_action_released("ui_attack") and not sword_animation_player.is_playing():
		sword_animation_player.play("attack")
		attack_sfx.play()


func _on_frame_changed() -> void:
	if not animated_sprite.animation == "move":
		return
	
	match animated_sprite.frame:
		1,4:
			footsteps_sfx.play()


func _on_hitbox_component_hit() -> void:
	hit_stf.play(1.1)


func _on_input_component_direction_changed(new_movement_direction: Vector2) -> void:
	movement_component.move(new_movement_direction)


func _on_took_damage() -> void:
	hurt_sfx.play()


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	state_machine.set_state(state_machine.states.dead)


func _on_dialogue_started(dialogue : DialogueResource) -> void:
	state_machine.set_state(state_machine.states.idle)
	state_machine.active = false


func _on_dialogue_ended(dialogue : DialogueResource) -> void:
	state_machine.active = true
