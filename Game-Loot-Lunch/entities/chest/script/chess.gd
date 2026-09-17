extends Area2D

@export var gold_value: int = 10
@export var chest_id: String = "chest_1"
@export var is_open: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision: CollisionShape2D = $CollisionShape2D

signal chest_opened(value: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if PlayerWallet.is_chest_opened(chest_id):
		is_open = true
	
	update_chest_state()

func update_chest_state() -> void:
	if is_open:
		anim.play("open")
		collision.set_deferred("disabled", true)
	else:
		anim.play("close")

func _on_body_entered(_body: Node2D) -> void:
	if is_open:
		return
	
	open_chest()

func open_chest() -> void:
	is_open = true
	
	PlayerWallet.add_gold(gold_value)
	PlayerWallet.mark_chest_opened(chest_id)
	
	audio_stream.pitch_scale = 1.0
	audio_stream.play()
	
	anim.play("open")
	await anim.animation_finished
	
	collision.set_deferred("disabled", true)
	chest_opened.emit(gold_value)
	
	#print("🎁 Baú ", chest_id, " aberto! +", gold_value, " gold")
