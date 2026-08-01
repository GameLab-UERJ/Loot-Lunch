extends Area2D

@export var gold_value: int = 1
@export var is_single_use: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision: CollisionShape2D = $CollisionShape2D

signal gold_collected(value: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	collect_gold()

func collect_gold() -> void:
	print("💰 Gold antes: ", PlayerWallet.gold)
	
	PlayerWallet.add_gold(gold_value)
	
	print("💰 +", gold_value, " | Gold depois: ", PlayerWallet.gold)
	
	audio_stream.pitch_scale = randf_range(0.9, 1.1)
	audio_stream.play()
	
	gold_collected.emit(gold_value)
	
	if is_single_use:
		collision.set_deferred("disabled", true)
		queue_free()
