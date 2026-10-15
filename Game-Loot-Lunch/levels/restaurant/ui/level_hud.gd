extends CanvasLayer
class_name LevelHUD
## HUD da FASE (canto superior direito): tempo do turno, dinheiro x meta e o placar
## de clientes. Também mostra o aviso de início e a tela de fim de turno.
##
## Só DESENHA. Quem decide tempo, meta e vitória é a fase (RestaurantLevel), que chama
## `setup`, `set_time_left`, `set_money`, `set_customers` e `show_end`.
## O HUD do chef (vida, mana, dinheiro) continua no chef.
##
## process_mode = ALWAYS: o botão "Jogar de novo" funciona com o jogo pausado.


signal restart_requested
signal exit_requested


## Tempo (s) em que o relógio fica vermelho e pisca.
@export var warning_time: float = 30.0
@export var normal_color: Color = Color(0.95, 0.92, 0.85)
@export var warning_color: Color = Color(0.96, 0.28, 0.24)
@export var goal_done_color: Color = Color(0.3, 0.88, 0.35)
## Cor do placar depois de passar (1ª estrela) e antes de fazer todas.
@export var star_color: Color = Color(1.0, 0.82, 0.3)
## Símbolos da linha de estrelas na tela de fim (a fonte Silver tem ★ e ☆).
@export var star_full: String = "★"
@export var star_empty: String = "☆"
## Segundos que o aviso de início fica na tela.
@export var banner_time: float = 2.5


@export_group("Audio")
@export var hover_sound: AudioStream = preload("res://assets/sfx/menus/abs-pointer-2.mp3")
@export var press_sound: AudioStream = preload("res://assets/sfx/menus/abs-confirm-2.mp3")


@onready var time_label: Label = %Tempo
@onready var money_label: Label = %Meta
@onready var customers_label: Label = %Clientes
@onready var banner: Label = %Aviso
@onready var end_screen: Control = %FimDeTurno
@onready var end_title: Label = %Titulo
@onready var end_stats: Label = %Resumo
@onready var restart_button: Button = %JogarDeNovo
@onready var exit_button: Button = %SairRestaurante

var _goal: int = 0
## Metas de estrela em ordem crescente (1 só = fase sem estrelas).
var _star_goals: Array[int] = []
var _hover_audio: AudioStreamPlayer
var _press_audio: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	end_screen.hide()
	banner.hide()

	_hover_audio = AudioStreamPlayer.new()
	_hover_audio.stream = hover_sound
	add_child(_hover_audio)

	_press_audio = AudioStreamPlayer.new()
	_press_audio.stream = press_sound
	add_child(_press_audio)

	restart_button.mouse_entered.connect(func() -> void:
		if _hover_audio and _hover_audio.stream and end_screen.visible:
			_hover_audio.play()
	)
	restart_button.pressed.connect(func() -> void:
		if _press_audio and _press_audio.stream:
			_press_audio.play()
		restart_requested.emit()
	)

	exit_button.mouse_entered.connect(func() -> void:
		if _hover_audio and _hover_audio.stream and end_screen.visible:
			_hover_audio.play()
	)
	exit_button.pressed.connect(func() -> void:
		if _press_audio and _press_audio.stream:
			_press_audio.play()
		exit_requested.emit()
	)


## Começo da fase: guarda a meta e mostra o aviso "Fase 1 — Meta: 50".
## `star_goals` = metas de estrela em ordem crescente (vazio = só `goal`, sem estrelas).
func setup(level_name: String, goal: int, duration: float, currency: String,
		star_goals: Array[int] = []) -> void:
	_goal = goal
	_star_goals = star_goals.duplicate()
	if _star_goals.is_empty():
		_star_goals.append(goal)
	set_time_left(duration)
	set_money(0)
	set_customers(0, 0)
	banner.text = "%s\nMeta: %d %s em %s" % [level_name, goal, currency, format_time(duration)]
	if _star_goals.size() > 1:
		var parts: PackedStringArray = []
		for g in _star_goals:
			parts.append(str(g))
		banner.text += "\nEstrelas: %s" % " / ".join(parts)
	banner.show()
	banner.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(banner_time)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.hide)


func set_time_left(seconds: float) -> void:
	time_label.text = "Tempo %s" % format_time(seconds)
	var warning: bool = seconds <= warning_time
	var blink: bool = warning and fmod(seconds, 1.0) > 0.5
	time_label.add_theme_color_override(&"font_color", warning_color if warning and not blink else normal_color)


## Placar: mostra a PRÓXIMA meta (50 -> 75 -> 100) e quantas estrelas já valem.
## Branco = ainda não passa, dourado = já passa, verde = todas as estrelas.
func set_money(amount: int) -> void:
	var stars: int = count_stars(amount)
	var max_stars: int = _star_goals.size()
	money_label.text = "Meta: %d / %d" % [amount, next_goal(amount)]
	if max_stars > 1:
		money_label.text += "\nEstrelas: %d / %d" % [stars, max_stars]
	var color: Color = normal_color
	if stars >= max_stars:
		color = goal_done_color
	elif stars > 0:
		color = star_color
	money_label.add_theme_color_override(&"font_color", color)


func count_stars(amount: int) -> int:
	var stars: int = 0
	for g in _star_goals:
		if amount >= g:
			stars += 1
	return stars


func next_goal(amount: int) -> int:
	for g in _star_goals:
		if amount < g:
			return g
	return _star_goals[_star_goals.size() - 1] if not _star_goals.is_empty() else _goal


## "★★☆" para 2 de 3.
func star_line(stars: int, max_stars: int) -> String:
	return star_full.repeat(clampi(stars, 0, max_stars)) + star_empty.repeat(maxi(max_stars - stars, 0))


func set_customers(served: int, lost: int) -> void:
	customers_label.text = "Atendidos: %d   Perdidos: %d" % [served, lost]


## Fim do turno. `stats` aceita: money, goal, stars, max_stars, served, correct, lost.
func show_end(success: bool, reason: String, stats: Dictionary) -> void:
	end_title.text = "Meta batida!" if success else "Fim de turno!"
	end_title.add_theme_color_override(&"font_color", goal_done_color if success else warning_color)
	var money: int = stats.get("money", 0)
	var max_stars: int = stats.get("max_stars", _star_goals.size())
	var stars: int = stats.get("stars", count_stars(money))
	var lines: PackedStringArray = []
	if reason != "":
		lines.append(reason)
	if max_stars > 1:
		lines.append(star_line(stars, max_stars))
	lines.append("Dinheiro: %d / %d" % [money, next_goal(money) if success else stats.get("goal", _goal)])
	lines.append("Atendidos: %d  (certos: %d)" % [stats.get("served", 0), stats.get("correct", 0)])
	lines.append("Clientes perdidos: %d" % stats.get("lost", 0))
	end_stats.text = "\n".join(lines)
	end_screen.show()
	restart_button.grab_focus()


static func format_time(seconds: float) -> String:
	var total: int = maxi(ceili(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]
