extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var is_single_use: bool = true

signal key_collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	collect_key()

func collect_key() -> void:
	audio_stream.pitch_scale = 1.2
	audio_stream.play()
	
	key_collected.emit()
	
	if anim and anim.sprite_frames.has_animation("collected"):
		anim.play("collected")
		await anim.animation_finished
	
	if is_single_use:
		collision.set_deferred("disabled", true)
		visible = false
