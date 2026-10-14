extends StaticBody2D
class_name TrashBin


signal item_discarded(item: CarryableItem)


@export var accepts_items: bool = true

@export_group("Áudio")
@export var clank_stream: AudioStream = preload("res://assets/sfx/restaurante/estacoes/trash_clank.wav")
@export var smoke_stream: AudioStream = preload("res://assets/sfx/restaurante/estacoes/trash_smoke.wav")

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var vanish_effect: SpriteSheetEffect = $VanishEffect

var _clank_player: AudioStreamPlayer2D = null
var _smoke_player: AudioStreamPlayer2D = null


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	interactable.alt_interacted.connect(_on_interacted)
	if clank_stream:
		_clank_player = AudioStreamPlayer2D.new()
		_clank_player.name = "ClankSfx"
		_clank_player.stream = clank_stream
		_clank_player.bus = &"SFX"
		add_child(_clank_player)
	if smoke_stream:
		_smoke_player = AudioStreamPlayer2D.new()
		_smoke_player.name = "SmokeSfx"
		_smoke_player.stream = smoke_stream
		_smoke_player.bus = &"SFX"
		add_child(_smoke_player)


func can_react_to(actor: Node) -> bool:
	if not accepts_items:
		return false
	var hand: HandComponent = HandComponent.find_in(actor)
	return hand != null and not hand.is_empty()


func _on_interacted(actor: Node) -> void:
	if not accepts_items:
		return
	var hand: HandComponent = HandComponent.find_in(actor)
	if hand == null or hand.is_empty():
		return
	var item: CarryableItem = hand.consume_item_with_effect(vanish_effect)
	if item:
		if _clank_player:
			_clank_player.pitch_scale = randf_range(0.95, 1.05)
			_clank_player.play()
		if _smoke_player:
			_smoke_player.pitch_scale = randf_range(0.95, 1.05)
			_smoke_player.play()
		item_discarded.emit(item)
