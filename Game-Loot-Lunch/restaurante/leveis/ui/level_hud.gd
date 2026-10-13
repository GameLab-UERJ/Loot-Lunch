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


## Tempo (s) em que o relógio fica vermelho e pisca.
@export var warning_time: float = 30.0
@export var normal_color: Color = Color(0.95, 0.92, 0.85)
@export var warning_color: Color = Color(1.0, 0.4, 0.35)
@export var goal_done_color: Color = Color(0.55, 1.0, 0.55)
## Segundos que o aviso de início fica na tela.
@export var banner_time: float = 2.5


@onready var time_label: Label = %Tempo
@onready var money_label: Label = %Meta
@onready var customers_label: Label = %Clientes
@onready var banner: Label = %Aviso
@onready var end_screen: Control = %FimDeTurno
@onready var end_title: Label = %Titulo
@onready var end_stats: Label = %Resumo
@onready var restart_button: Button = %JogarDeNovo


var _goal: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	end_screen.hide()
	banner.hide()
	restart_button.pressed.connect(func() -> void: restart_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not end_screen.visible:
		return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		restart_requested.emit()


## Começo da fase: guarda a meta e mostra o aviso "Fase 1 — Meta: 60".
func setup(level_name: String, goal: int, duration: float, currency: String) -> void:
	_goal = goal
	set_time_left(duration)
	set_money(0)
	set_customers(0, 0)
	banner.text = "%s\nMeta: %d %s em %s" % [level_name, goal, currency, format_time(duration)]
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


func set_money(amount: int) -> void:
	money_label.text = "Meta %d / %d" % [amount, _goal]
	money_label.add_theme_color_override(&"font_color", goal_done_color if amount >= _goal else normal_color)


func set_customers(served: int, lost: int) -> void:
	customers_label.text = "Atendidos %d   Perdidos %d" % [served, lost]


## Fim do turno. `stats` aceita: money, goal, served, correct, lost.
func show_end(success: bool, reason: String, stats: Dictionary) -> void:
	end_title.text = "Meta batida!" if success else "Não deu..."
	end_title.add_theme_color_override(&"font_color", goal_done_color if success else warning_color)
	var lines: PackedStringArray = []
	if reason != "":
		lines.append(reason)
	lines.append("Dinheiro: %d / %d" % [stats.get("money", 0), stats.get("goal", _goal)])
	lines.append("Atendidos: %d  (certos: %d)" % [stats.get("served", 0), stats.get("correct", 0)])
	lines.append("Clientes perdidos: %d" % stats.get("lost", 0))
	end_stats.text = "\n".join(lines)
	end_screen.show()
	restart_button.grab_focus()


static func format_time(seconds: float) -> String:
	var total: int = maxi(ceili(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]
