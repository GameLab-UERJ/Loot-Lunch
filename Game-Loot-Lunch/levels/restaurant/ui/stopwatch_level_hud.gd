extends LevelHUD
class_name StopwatchLevelHUD
## HUD da fase com CRONÔMETRO. Usa a mesma cena do HUD da fase com turno
## (hud_fase.tscn), só troca o script: o relógio conta para FRENTE, o placar mostra
## clientes atendidos / total e a próxima estrela que ainda dá para pegar.
##
## Fontes: a Sta.Toasty (Tempo/Meta/Clientes/Aviso) não tem acentos nem ★, por isso
## esses textos são escritos sem acento. O resumo do fim usa a Silver (tem ★ e acentos).


@export var exit_text: String = "Voltar ao mapa"
## Dica de teclas fixa no rodapé (vazio = sem dica).
@export_multiline var controls_hint: String = ""
@export var hint_font: Font = preload("res://assets/fonts/Silver.ttf")


var _data: StopwatchLevelData = null
var _hint: Label = null


func setup_stopwatch(level_name: String, data: StopwatchLevelData) -> void:
	_data = data
	exit_button.text = exit_text
	set_elapsed(0.0)
	set_progress(0, 0, data.total_customers, 0.0)
	var lines: PackedStringArray = [level_name, "%d clientes" % data.total_customers]
	for i in data.get_max_stars():
		lines.append(_star_rule_text(i, false))
	banner.text = "\n".join(lines)
	banner.show()
	banner.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(banner_time + 1.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.hide)
	_build_hint()


func set_elapsed(seconds: float) -> void:
	time_label.text = "Tempo %s" % format_elapsed(seconds)
	time_label.add_theme_color_override(&"font_color", normal_color)


## served = atendidos (certos + errados); total = clientes da fase.
func set_progress(served: int, correct: int, total: int, seconds: float) -> void:
	customers_label.text = "Clientes %d / %d   Certos %d" % [served, total, correct]
	if _data == null:
		return
	var remaining: int = maxi(total - served, 0)
	var best: int = _data.reachable_stars(seconds, correct, remaining)
	var color: Color = warning_color
	if best >= _data.get_max_stars():
		color = goal_done_color
	elif best > 0:
		color = star_color
	if best <= 0:
		money_label.text = "Sem estrelas"
	else:
		var limit: float = _data.time_limit_of(best - 1)
		var stars_word: String = "estrela" if best == 1 else "estrelas"
		money_label.text = "%d %s: %d certos" % [best, stars_word, _data.star_min_correct[best - 1]]
		if limit > 0.0:
			money_label.text += " ate %s" % format_elapsed(limit)
	money_label.add_theme_color_override(&"font_color", color)


## Fim da fase. `stats`: stars, max_stars, served, correct, total, time.
func show_end(success: bool, reason: String, stats: Dictionary) -> void:
	end_title.text = "Fase completa!" if success else "Tente de novo"
	end_title.add_theme_color_override(&"font_color", goal_done_color if success else warning_color)
	var lines: PackedStringArray = []
	if reason != "":
		lines.append(reason)
	var max_stars: int = stats.get("max_stars", 3)
	lines.append(star_line(stats.get("stars", 0), max_stars))
	lines.append("Tempo: %s" % format_elapsed(stats.get("time", 0.0)))
	var correct: int = stats.get("correct", 0)
	var served: int = stats.get("served", 0)
	lines.append("Pedidos certos: %d / %d" % [correct, stats.get("total", served)])
	if served - correct > 0:
		lines.append("Pedidos errados: %d" % (served - correct))
	if _data:
		for i in _data.get_max_stars():
			lines.append(_star_rule_text(i, true))
	end_stats.text = "\n".join(lines)
	end_screen.show()
	restart_button.grab_focus()


## Cronômetro: arredonda para baixo (0:00, 0:01...).
static func format_elapsed(seconds: float) -> String:
	var total: int = maxi(floori(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]


func _star_rule_text(index: int, rich: bool) -> String:
	var limit: float = _data.time_limit_of(index)
	var prefix: String = (star_full.repeat(index + 1) + "  ") if rich else "%d estrela%s: " % [index + 1, "" if index == 0 else "s"]
	var text: String = "%s%d certos" % [prefix, _data.star_min_correct[index]]
	if limit > 0.0:
		text += (" em até %s" if rich else " ate %s") % format_elapsed(limit)
	return text


func _build_hint() -> void:
	if controls_hint == "" or _hint != null:
		return
	_hint = Label.new()
	_hint.name = "DicaTeclas"
	_hint.text = controls_hint
	_hint.add_theme_font_override(&"font", hint_font)
	_hint.add_theme_font_size_override(&"font_size", 16)
	_hint.add_theme_color_override(&"font_color", Color(0.92, 0.9, 0.98, 0.95))
	_hint.add_theme_color_override(&"font_outline_color", Color(0.08, 0.04, 0.1, 1))
	_hint.add_theme_constant_override(&"outline_size", 4)
	_hint.add_theme_constant_override(&"line_spacing", -4)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_right = -6
	_hint.offset_bottom = -2
	add_child(_hint)
	move_child(_hint, 0)
