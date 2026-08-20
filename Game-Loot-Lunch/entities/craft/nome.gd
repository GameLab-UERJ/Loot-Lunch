extends Control

@export_category("Interaction")
@export var interaction_name: String = "Interagir"
@export var interactable_area: Area2D
@export var label: Label  # Arraste a Label aqui no Inspector

func _ready() -> void:
	visible = false
	
	if interactable_area:
		if not interactable_area.body_entered.is_connected(_on_interactable_area_body_entered):
			interactable_area.body_entered.connect(_on_interactable_area_body_entered)
		if not interactable_area.body_exited.is_connected(_on_interactable_area_body_exited):
			interactable_area.body_exited.connect(_on_interactable_area_body_exited)

func _on_interactable_area_body_entered(body: Node2D) -> void:
	visible = true

func _on_interactable_area_body_exited(body: Node2D) -> void:
	visible = false
