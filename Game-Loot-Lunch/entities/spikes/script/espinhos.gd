extends Enemy
class_name SpikeTrap

@onready var hitbox_component: Area2D = $HitboxComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D

var can_damage: bool = false


func _ready() -> void:
	player = null
	
	if collision_shape:
		collision_shape.disabled = true
	
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	animated_sprite.play("default")


func _on_frame_changed() -> void:
	if animated_sprite.animation == "default":
		if animated_sprite.frame == 3:
			enable_damage()
		else:
			disable_damage()


func enable_damage() -> void:
	can_damage = true
	if collision_shape:
		collision_shape.disabled = false


func disable_damage() -> void:
	can_damage = false
	if collision_shape:
		collision_shape.disabled = true


func _on_animation_finished() -> void:
	if animated_sprite.animation == "default":
		animated_sprite.play("default")


func _on_got_hurt() -> void:
	pass


func _on_died() -> void:
	pass
