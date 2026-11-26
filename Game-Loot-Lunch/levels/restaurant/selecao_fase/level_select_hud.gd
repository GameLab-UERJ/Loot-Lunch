extends CanvasLayer
class_name LevelSelectHUD
## HUD do mapa de seleção: placa com o nome do mapa + estrelas no canto, painel da fase
## embaixo (número, nome, estrelas e a dica de tecla) e um aviso rápido no meio.
## Só mostra o que o `LevelSelectMap` mandar.


@onready var title_label: Label = %Titulo
@onready var stars_label: Label = %TotalEstrelas
@onready var info_panel: Control = %PainelFase
@onready var id_label: Label = %NumeroFase
@onready var name_label: Label = %NomeFase
@onready var node_stars_label: Label = %EstrelasFase
@onready var hint_label: Label = %Dica
@onready var flash_label: Label = %Aviso


var _shown: LevelSelectNode = null
var _panel_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	info_panel.visible = false
	info_panel.modulate.a = 0.0
	flash_label.modulate.a = 0.0


func setup(map_title: String, total_stars: int, max_stars: int) -> void:
	title_label.text = map_title.to_upper()
	stars_label.text = "★ %d / %d" % [total_stars, max_stars]


func show_node(node: LevelSelectNode, hint: String) -> void:
	hint_label.text = hint
	if node == _shown:
		return
	_shown = node
	id_label.text = "Fase %s" % node.level_id
	name_label.text = node.level_name
	var text := ""
	for i in node.max_stars:
		text += "★" if i < node.stars else "☆"
	node_stars_label.text = text
	node_stars_label.visible = not node.locked
	var color := Color(0.78, 0.74, 0.86) if node.locked else Color(1.0, 0.95, 0.82)
	name_label.add_theme_color_override(&"font_color", color)
	info_panel.visible = true
	_fade_panel(1.0)


func hide_node() -> void:
	if _shown == null:
		return
	_shown = null
	_fade_panel(0.0)


func flash(text: String) -> void:
	flash_label.text = text
	if _flash_tween:
		_flash_tween.kill()
	flash_label.modulate.a = 1.0
	flash_label.scale = Vector2(1.25, 1.25)
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_label, "scale", Vector2.ONE, 0.15)
	_flash_tween.tween_interval(0.9)
	_flash_tween.tween_property(flash_label, "modulate:a", 0.0, 0.4)


func _fade_panel(target: float) -> void:
	if _panel_tween:
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(info_panel, "modulate:a", target, 0.15)
	if target <= 0.0:
		_panel_tween.tween_callback(func(): info_panel.visible = false)
