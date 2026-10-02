extends CanvasLayer
class_name BattleMenu
## MENU de habilidades do chef na batalha por turnos (4 botões estilo Pokémon).
##
##   var skill: BattleSkill = await menu.choose(chef, formiga)
##
## Teclas 1-4 ou clique. Habilidade indisponível (sem mana, Devorar com a formiga acima
## de 20%...) fica apagada e, se tentar usar, mostra o motivo. Não sabe o que cada
## habilidade faz: lê nome, ícone, custo e descrição do próprio BattleSkill.


signal skill_chosen(skill: BattleSkill)


## Teclas de atalho, na ordem dos botões.
@export var hotkeys: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4]
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.9)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)


var _skills: Array[BattleSkill] = []
var _user: ChefBattler
var _target: FormigaBattler
var _buttons: Array[Button] = []
var _description: Label
var _root: Control
var _open: bool = false


func _init() -> void:
	layer = 15


func _ready() -> void:
	_build()
	_root.hide()


func choose(user: ChefBattler, target: FormigaBattler) -> BattleSkill:
	_user = user
	_target = target
	_skills = user.skills
	_refresh()
	_root.show()
	_open = true
	var skill: BattleSkill = await skill_chosen
	_open = false
	_root.hide()
	return skill


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = hotkeys.find(key.keycode)
	if index >= 0 and index < _skills.size():
		get_viewport().set_input_as_handled()
		_try(index)


func _try(index: int) -> void:
	if not _open:
		return
	var skill: BattleSkill = _skills[index]
	var reason: String = skill.why_not(_user, _target)
	if reason != "":
		_description.text = "%s: %s" % [skill.display_name, reason]
		_description.modulate = Color(1.0, 0.5, 0.45)
		if skill.mana_cost > 0 and _user.mana and not _user.mana.has(skill.mana_cost):
			_user.mana.insufficient.emit(skill.mana_cost, _user.mana.mana)  # treme a barra
		return
	_open = false
	skill_chosen.emit(skill)


func _refresh() -> void:
	for i in _buttons.size():
		var button: Button = _buttons[i]
		if i >= _skills.size():
			button.hide()
			continue
		var skill: BattleSkill = _skills[i]
		button.show()
		button.icon = skill.icon
		var cost: String = ""
		if skill.mana_cost > 0:
			cost = "  [%d mana]" % skill.mana_cost
		elif skill.mana_gain > 0:
			cost = "  [+%d mana]" % skill.mana_gain
		button.text = "%d %s%s" % [i + 1, skill.display_name, cost]
		var usable: bool = skill.can_use(_user, _target)
		button.modulate = Color.WHITE if usable else Color(0.55, 0.5, 0.6)
	_description.text = "Escolha uma habilidade (1-4 ou clique)"
	_description.modulate = Color.WHITE


func _on_hover(index: int) -> void:
	if index < _skills.size():
		var skill: BattleSkill = _skills[index]
		var reason: String = skill.why_not(_user, _target) if _user else ""
		_description.text = skill.description if reason == "" else "%s  (%s)" % [skill.description, reason]
		_description.modulate = Color.WHITE


func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_root.offset_top = -64.0
	_root.offset_left = 6.0
	_root.offset_right = -6.0
	_root.offset_bottom = -4.0
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_content_margin_all(4)
	_root.add_theme_stylebox_override("panel", style)
	add_child(_root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_root.add_child(column)

	_description = Label.new()
	_description.add_theme_font_size_override("font_size", 9)
	_description.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.12))
	_description.add_theme_constant_override("outline_size", 3)
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_description)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	column.add_child(grid)
	for i in hotkeys.size():
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE  # ESPAÇO é do QTE, não do botão
		button.custom_minimum_size = Vector2(150, 30)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 9)
		button.add_theme_constant_override("icon_max_width", 20)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_try.bind(i))
		button.mouse_entered.connect(_on_hover.bind(i))
		grid.add_child(button)
		_buttons.append(button)
