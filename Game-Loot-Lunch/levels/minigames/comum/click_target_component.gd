extends Node2D
class_name ClickTargetComponent
## Alvo de CLIQUE do mouse (esquerdo) em um círculo: fagulha do Mini-Sol, buraco da
## toupeira, botão no mundo... Pendure como filho de quem pode ser clicado e escute
## `clicked`. Não precisa de física (nem de `physics_object_picking`): compara a
## distância do mouse com `radius`, então funciona com qualquer câmera/escala.
##
## O primeiro alvo que aceitar o clique "consome" o evento (dois alvos sobrepostos não
## disparam juntos). Desligue com `enabled = false`.


signal clicked
signal hover_changed(is_hovered: bool)


@export var enabled: bool = true
@export var click_action: StringName = &"left_click"
@export var radius: float = 10.0
## Desenha um anel quando o mouse está em cima (ajuda a mirar em coisas pequenas).
@export var show_hover_ring: bool = true
@export var hover_color: Color = Color(1.0, 1.0, 1.0, 0.8)


var is_hovered: bool = false


func _process(_delta: float) -> void:
	var hovered: bool = enabled and is_visible_in_tree() and _mouse_inside()
	if hovered != is_hovered:
		is_hovered = hovered
		hover_changed.emit(is_hovered)
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		return
	var pressed: bool = false
	if click_action != &"" and InputMap.has_action(click_action):
		pressed = event.is_action_pressed(click_action)
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed and _mouse_inside():
		get_viewport().set_input_as_handled()
		clicked.emit()


func _mouse_inside() -> bool:
	return get_global_mouse_position().distance_to(global_position) <= radius * global_scale.x


func _draw() -> void:
	if is_hovered and show_hover_ring:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, hover_color, 1.0)
