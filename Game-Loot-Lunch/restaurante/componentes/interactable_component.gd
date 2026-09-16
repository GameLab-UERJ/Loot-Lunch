extends Area2D
class_name InteractableComponent
## Coloque em qualquer coisa da cozinha que reage à tecla de interação
## (bancada, caixa de ingredientes, fogão, lixeira, balcão de entrega...).
## A lógica fica no dono, conectado ao sinal `interacted`.
##
## Camada sugerida: collision_layer = 8 (camada 4 "interactables"), mask = 0.


signal interacted(actor: Node)
signal focus_changed(is_focused: bool)


@export var enabled: bool = true
## Nó que brilha quando o jogador está mirando nele (opcional).
@export var highlight_target: CanvasItem
@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)


var is_focused: bool = false
var _original_modulate: Color = Color.WHITE


func _ready() -> void:
	if highlight_target:
		_original_modulate = highlight_target.modulate


func can_interact(_actor: Node) -> bool:
	return enabled


func interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false
	interacted.emit(actor)
	return true


func set_focused(value: bool) -> void:
	if is_focused == value:
		return
	is_focused = value
	if highlight_target:
		highlight_target.modulate = highlight_modulate if value else _original_modulate
	focus_changed.emit(value)
