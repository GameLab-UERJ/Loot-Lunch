extends StaticBody2D

@export var keys_needed: int = 1

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D

var keys_collected: int = 0
var is_open: bool = false

func _ready() -> void:
	anim.play("close")

func _on_key_collected() -> void:
	keys_collected += 1
	print("Chave coletada: ", keys_collected, "/", keys_needed)
	
	if keys_collected >= keys_needed and not is_open:
		open_door()

func open_door() -> void:
	is_open = true
	
	audio_stream.pitch_scale = 1.0
	audio_stream.play()
	
	anim.play("open")
	await anim.animation_finished
	
	collision.set_deferred("disabled", true)

func close_door() -> void:
	keys_collected -= 1
	print("Chave removida: ", keys_collected, "/", keys_needed)
	
	if is_open and keys_collected < keys_needed:
		is_open = false
		collision.set_deferred("disabled", false)
		anim.play("close")


func _on_key_2_door_final_2_key_collected() -> void:
	pass # Replace with function body.
