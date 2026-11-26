extends InputComponent
class_name ActionInputComponent
## InputComponent com as TECLAS ESCOLHIDAS NO INSPECTOR.
##
## O InputComponent original lê sempre `ui_up/down/left/right` (WASD + setas juntos),
## então dois jogadores no mesmo teclado andariam juntos. Este aqui é igual a ele
## (mesmo sinal `direction_changed`, mesmo `get_input()`), só que cada um lê as
## SUAS ações do Input Map. Por herdar de InputComponent, encaixa em qualquer
## personagem que já espera um InputComponent (chef, brasa...) sem mudar código.
##
## Padrão = ações `ui_*`: trocar o script de um InputComponent por este não muda nada
## até alguém preencher outras ações.


@export var up_action: StringName = &"ui_up"
@export var down_action: StringName = &"ui_down"
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"


func get_input() -> void:
	var mov_direction: Vector2 = Vector2.ZERO
	if _is_pressed(down_action):
		mov_direction += Vector2.DOWN
	if _is_pressed(left_action):
		mov_direction += Vector2.LEFT
	if _is_pressed(right_action):
		mov_direction += Vector2.RIGHT
	if _is_pressed(up_action):
		mov_direction += Vector2.UP

	direction_changed.emit(mov_direction)


func _is_pressed(action: StringName) -> bool:
	return action != &"" and InputMap.has_action(action) and Input.is_action_pressed(action)
