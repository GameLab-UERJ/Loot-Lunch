extends CanvasLayer
class_name BattleMenu
## MENU de habilidades do chef na batalha da Fase 3 (4 botões estilo Pokémon), ligado
## ao TEMPO DE ESPERA do chef:
##
##   menu.open(chef, alvo)      # mostra o painel (fica aberto a luta inteira)
##   menu.set_ready(true)       # barra do chef cheia: botões acesos
##   menu.lock(true)            # alguém está atacando: ignora as teclas
##   menu.skill_chosen          # o jogador escolheu (a batalha decide QUANDO sai)
##   menu.target_step(+1 / -1)  # ◀ ▶ (ou A D / W S) para trocar o alvo
##
## Teclas 1-4 ou clique. Escolher com a barra ainda enchendo AGENDA a habilidade (sai
## assim que encher). Habilidade indisponível (sem mana, Devorar com a formiga acima de
## 20%...) fica apagada e, se tentar usar, mostra o motivo. Não sabe o que cada
## habilidade faz: lê nome, ícone, custo e descrição do próprio BattleSkill.


signal skill_chosen(skill: BattleSkill)
## Pediu para trocar de alvo (+1 próximo, -1 anterior).
signal target_step(step: int)


## Teclas de atalho, na ordem dos botões.
@export var hotkeys: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4]
@export var next_target_actions: Array[StringName] = [&"ui_right", &"ui_down"]
@export var previous_target_actions: Array[StringName] = [&"ui_left", &"ui_up"]
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.9)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var queued_color: Color = Color(0.55, 0.85, 1.0, 1.0)


var _skills: Array[BattleSkill] = []
var _user: ChefBattler
var _target: FormigaBattler
var _buttons: Array[Button] = []
var _description: Label
var _root: Control
var _open: bool = false
var _locked: bool = false
var _chef_ready: bool = false
var _queued: BattleSkill = null
var _message_time: float = 0.0


func _init() -> void:
	layer = 15


func _ready() -> void:
	_build()
	_root.hide()


func open(user: ChefBattler, target: FormigaBattler) -> void:
	_user = user
	_target = target
	_skills = user.skills
	_open = true
	_locked = false
	_root.show()
	_refresh()


func close() -> void:
	_open = false
	_root.hide()


func is_open() -> bool:
	return _open


func set_target(target: FormigaBattler) -> void:
	_target = target
	if _open:
		_refresh()


func set_ready(value: bool) -> void:
	_chef_ready = value
	if _open:
		_refresh()


func set_queued(skill: BattleSkill) -> void:
	_queued = skill
	if _open:
		_refresh()


## Travado = alguém está atacando (as teclas não fazem nada e o painel escurece).
func lock(value: bool) -> void:
	_locked = value
	_root.modulate = Color(1, 1, 1, 0.45) if value else Color.WHITE
	if _open and not value:
		_refresh()


## Mostra por que a habilidade não saiu.
func show_reason(skill: BattleSkill) -> void:
	var reason: String = skill.why_not(_user, _target) if _user else ""
	_show_message("%s: %s" % [skill.display_name, reason if reason != "" else "não deu"], Color(1.0, 0.5, 0.45))


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0 and _open:
			_refresh()
	# Atualiza os botões (mana e vida do alvo mudam o tempo todo).
	if _open and not _locked and Engine.get_process_frames() % 6 == 0:
		_refresh_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _locked:
		return
	for action in next_target_actions:
		if InputMap.has_action(action) and event.is_action_pressed(action) and not event.is_echo():
			get_viewport().set_input_as_handled()
			target_step.emit(1)
			return
	for action in previous_target_actions:
		if InputMap.has_action(action) and event.is_action_pressed(action) and not event.is_echo():
			get_viewport().set_input_as_handled()
			target_step.emit(-1)
			return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = hotkeys.find(key.keycode)
	if index >= 0 and index < _skills.size():
		get_viewport().set_input_as_handled()
		_try(index)


func _try(index: int) -> void:
	if not _open or _locked:
		return
	var skill: BattleSkill = _skills[index]
	var reason: String = skill.why_not(_user, _target)
	if reason != "":
		_show_message("%s: %s" % [skill.display_name, reason], Color(1.0, 0.5, 0.45))
		if skill.mana_cost > 0 and _user.mana and not _user.mana.has(skill.mana_cost):
			_user.mana.insufficient.emit(skill.mana_cost, _user.mana.mana)  # treme a barra
		return
	skill_chosen.emit(skill)


func _refresh() -> void:
	_refresh_buttons()
	if _message_time > 0.0:
		return
	var who: String = _target.display_name if _target else "—"
	if _queued and not _chef_ready:
		_description.text = "%s agendada  →  %s" % [_queued.display_name, who]
		_description.modulate = queued_color
	elif _chef_ready:
		_description.text = "SUA VEZ! (1-4)   Alvo: %s  [◀ ▶ troca]" % who
		_description.modulate = Color(0.75, 1.0, 0.65)
	else:
		_description.text = "Preparando...   Alvo: %s  [◀ ▶ troca]" % who
		_description.modulate = Color.WHITE


func _refresh_buttons() -> void:
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
		var usable: bool = _user != null and skill.can_use(_user, _target)
		if skill == _queued:
			button.modulate = queued_color
		elif not usable:
			button.modulate = Color(0.55, 0.5, 0.6)
		elif _chef_ready:
			button.modulate = Color.WHITE
		else:
			button.modulate = Color(0.85, 0.82, 0.78)


func _show_message(text: String, color: Color) -> void:
	_description.text = text
	_description.modulate = color
	_message_time = 1.2


func _on_hover(index: int) -> void:
	if index < _skills.size() and _message_time <= 0.0:
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
