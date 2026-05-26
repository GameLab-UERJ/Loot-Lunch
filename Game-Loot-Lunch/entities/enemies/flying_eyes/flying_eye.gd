extends Enemy

@onready var hitbox_component: HitboxComponent = $HitboxComponent

@onready var movement_component: MovementComponent = $MovementComponent


func _process(_delta: float) -> void:
	if movement_component.mov_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif movement_component.mov_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true

	hitbox_component.knockback_direction = velocity.normalized()
