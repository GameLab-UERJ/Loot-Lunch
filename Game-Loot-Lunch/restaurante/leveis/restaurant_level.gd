extends Node2D
class_name RestaurantLevel
## FASE do restaurante: liga as peças da cena e decide quando o turno acaba.
##
##   LevelData (.tres)  -> tempo, meta de dinheiro, ritmo e paciência dos clientes
##   Turno              -> CooldownComponent contando o tempo do turno
##   Diretor            -> CustomerDirector: chegada, pedido, magias e saída dos clientes
##   HudFase            -> LevelHUD: tempo, meta, placar e tela de fim
##   Chef               -> a carteira (WalletComponent) dele é o dinheiro da fase
##
## Fim do turno (tempo acabou): passou se o dinheiro >= meta.
## Chef caiu (vida 0) e `fail_on_chef_death`: derrota na hora.
##
## A fase não sabe montar cozinha nem cliente: a cena da fase (lvl_1.tscn...) posiciona
## as estações, e cada sistema cuida do seu pedaço. Fase nova = nova cena + novo .tres.


signal level_started
signal level_finished(success: bool)


@export var level_data: LevelData
@export var chef: Chef
@export var director: CustomerDirector
@export var shift: CooldownComponent
@export var hud: LevelHUD

@export_group("Fim")
## Pausa o jogo um instante depois do fim (os clientes terminam de sair antes).
@export var pause_on_end: bool = true
@export var pause_delay: float = 0.8
## Segundos que o chef fica caído antes da derrota (dá tempo de ver a animação).
@export var death_delay: float = 1.0


var wallet: WalletComponent = null
var _finished: bool = false
var _death_pending: bool = false
var _time_at_end: float = 0.0


func _ready() -> void:
	DayNightSwitch.disable(self)  # restaurante é interno: sem o efeito de dia e noite
	randomize()
	if level_data == null:
		push_error("RestaurantLevel '%s': falta o LevelData." % name)
		return
	wallet = WalletComponent.find_in(chef) if chef else null

	if director:
		if director.level_data == null:
			director.level_data = level_data
		director.customer_served.connect(_on_customers_changed.unbind(3))
		director.customer_lost.connect(_on_customers_changed.unbind(1))
	if wallet:
		wallet.amount_changed.connect(_on_money_changed)
	if chef:
		chef.health_changed.connect(_on_chef_health_changed)
	if hud:
		hud.restart_requested.connect(restart)
		hud.setup(level_data.display_name, level_data.money_goal, level_data.duration,
			wallet.currency_name if wallet else "Almas")

	shift.finished.connect(_on_shift_finished)
	shift.start(level_data.duration)
	if director:
		director.start()
	level_started.emit()


func _process(_delta: float) -> void:
	if hud and not _finished:
		hud.set_time_left(get_time_left())


func get_time_left() -> float:
	if _finished:
		return _time_at_end
	return shift.get_time_left() if shift and not shift.is_ready() else 0.0


func get_money() -> int:
	return wallet.amount if wallet else 0


func is_finished() -> bool:
	return _finished


## Encerra o turno agora.
func finish(success: bool, reason: String = "") -> void:
	if _finished:
		return
	_time_at_end = get_time_left()
	_finished = true
	shift.stop()
	if director:
		director.stop()
		director.dismiss_all()
	if hud:
		hud.set_time_left(get_time_left())
		hud.show_end(success, reason, {
			"money": get_money(),
			"goal": level_data.money_goal,
			"served": director.served_count if director else 0,
			"correct": director.correct_count if director else 0,
			"lost": director.lost_count if director else 0,
		})
	level_finished.emit(success)
	if pause_on_end:
		get_tree().create_timer(pause_delay, true).timeout.connect(func() -> void:
			if _finished:
				get_tree().paused = true)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- Sinais --------------------------------------------------------------------

func _on_shift_finished() -> void:
	var money: int = get_money()
	if money >= level_data.money_goal:
		finish(true, "Fim do turno!")
	else:
		finish(false, "O tempo acabou. Faltaram %d." % (level_data.money_goal - money))


func _on_money_changed(amount: int, _delta: int) -> void:
	if hud:
		hud.set_money(amount)


func _on_customers_changed() -> void:
	if hud and director:
		hud.set_customers(director.served_count, director.lost_count)


func _on_chef_health_changed(current: int, _maximum: int) -> void:
	if current > 0 or _finished or _death_pending or not level_data.fail_on_chef_death:
		return
	_death_pending = true
	get_tree().create_timer(death_delay).timeout.connect(func() -> void:
		_death_pending = false
		if chef and chef.is_dead():
			finish(false, "O chef caiu!"))
