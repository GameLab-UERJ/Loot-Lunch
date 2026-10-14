class_name CustomerPatienceBar
extends Control

const GREEN_FILL := preload("res://assets/art/ui/customer_patience/patience_fill_green.png")
const YELLOW_FILL := preload("res://assets/art/ui/customer_patience/patience_fill_yellow.png")
const RED_FILL := preload("res://assets/art/ui/customer_patience/patience_fill_red.png")

@onready var progress_bar: TextureProgressBar = $Progress
@onready var irritated_icon: TextureRect = $Irritated

var patience: float = 100.0


func _ready() -> void:
	set_patience(patience)


func set_patience(value: float) -> void:
	patience = clampf(value, 0.0, 100.0)
	progress_bar.value = patience
	progress_bar.texture_progress = _get_fill_texture()
	irritated_icon.visible = patience <= 25.0


func _get_fill_texture() -> Texture2D:
	if patience <= 30.0:
		return RED_FILL
	if patience <= 60.0:
		return YELLOW_FILL
	return GREEN_FILL