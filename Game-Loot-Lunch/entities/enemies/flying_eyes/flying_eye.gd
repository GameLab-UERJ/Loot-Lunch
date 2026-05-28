extends Enemy

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var wing_flap_sfx: AudioStreamPlayer2D = $WingFlapSfx


func _process(_delta: float) -> void:
	if movement_component.mov_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif movement_component.mov_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true

	hitbox_component.knockback_direction = velocity.normalized()


func _on_wing_flap() -> void:
	match animated_sprite.frame:
		2:
			wing_flap_sfx.pitch_scale = randf_range(0.9,1.1)
			wing_flap_sfx.play()
