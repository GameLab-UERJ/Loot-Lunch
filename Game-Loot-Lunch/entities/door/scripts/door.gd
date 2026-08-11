extends StaticBody2D

@export var keys_needed: int = 1
@export var door_id: String = "door_1"

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D

var keys_collected: int = 0
var is_open: bool = false

func _ready() -> void:
	if PlayerWallet.is_door_opened(door_id):
		is_open = true
		keys_collected = keys_needed
		anim.play("open")
		collision.set_deferred("disabled", true)
	else:
		anim.play("close")

func _on_key_collected() -> void:
	keys_collected += 1
	
	if keys_collected >= keys_needed and not is_open:
		open_door()

func open_door() -> void:
	is_open = true
	
	PlayerWallet.mark_door_opened(door_id)
	
	audio_stream.pitch_scale = 1.0
	audio_stream.play()
	
	anim.play("open")
	await anim.animation_finished
	
	collision.set_deferred("disabled", true)

func close_door() -> void:
	keys_collected -= 1
	
	if is_open and keys_collected < keys_needed:
		is_open = false
		collision.set_deferred("disabled", false)
		anim.play("close")
