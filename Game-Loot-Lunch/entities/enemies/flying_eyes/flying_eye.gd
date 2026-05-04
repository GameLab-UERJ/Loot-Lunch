extends Enemy

@onready var hitbox_component: HitboxComponent = $HitboxComponent

func _process(_delta: float) -> void:
	hitbox_component.knockback_direction = velocity.normalized()
