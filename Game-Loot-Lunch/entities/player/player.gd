extends Character
class_name Player

@onready var sword: Node2D = $Sword
@onready var sword_hitbox: HitboxComponent = $Sword/Node2D/Sprite2D/HitboxComponent
@onready var sword_animation_player: AnimationPlayer = $Sword/SwordAnimationPlayer
@onready var movement_component: MovementComponent = $MovementComponent


func _process(_delta: float) -> void:
	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()

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
	if event.is_action_released("ui_attack") and not sword_animation_player.is_playing():
		sword_animation_player.play("attack")
