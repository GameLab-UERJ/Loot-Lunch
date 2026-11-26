extends Node2D
class_name StopwatchLevel
## FASE COM CRONÔMETRO (ex.: 1-1 "Portão de Ossos").
##
##   StopwatchLevelData (.tres) -> quantos clientes, ritmo, paciência, regras das estrelas
##   Diretor   -> CustomerWaveDirector: clientes de vários lados até completar o total
##   HudFase   -> StopwatchLevelHUD (mesma cena do HUD da fase com turno)
##   MuroFogo  -> FireWall (opcional): acende no começo, antes do relógio andar
##
## O relógio anda PARA FRENTE. Todos os clientes atendidos = fim: as estrelas vêm dos
## pedidos certos e do tempo (StopwatchLevelData.stars_for_result). 0 estrela = não passou.
## Chef caiu (vida 0): com `fail_on_chef_death` é derrota; sem, ele volta depois de
## `revive_delay` segundos com a vida cheia (só perde tempo).
##
## O resultado fica guardado no mapa de seleção (LevelSelectMap.record_result) para a
## bandeira mostrar as estrelas e liberar a próxima fase.


signal level_started
signal level_finished(success: bool, stars: int)


@export var level_data: StopwatchLevelData
@export var chef: Chef
@export var director: CustomerWaveDirector
@export var hud: StopwatchLevelHUD
@export var fire_wall: FireWall

@export_group("Início")
## Espera depois de o muro acender, antes do relógio andar e os clientes virem.
@export var start_delay: float = 1.6
## Esconde a barra de mana do HUD do chef (as habilidades desta fase não gastam mana).
@export var hide_chef_mana: bool = true

@export_group("Fim")
## Cena do mapa de seleção ("Voltar ao mapa").
@export_file("*.tscn") var map_scene: String = "res://levels/restaurant/selecao_fase/reino_caveira/reino_caveira.tscn"
@export var pause_on_end: bool = true
@export var pause_delay: float = 0.8
@export var death_delay: float = 1.0
## Com `fail_on_chef_death` desligado no .tres: o chef caído volta depois deste tempo,
## com a vida cheia (o relógio não para: cair custa tempo, não a fase).
@export var revive_delay: float = 3.0

@export_group("Áudio")
@export var bgm: AudioStream = preload("res://assets/music/watermelon_beats-medieval-folk-music-505203.mp3")


var elapsed: float = 0.0
var _running: bool = false
var _finished: bool = false
var _death_pending: bool = false
var _bgm_player: AudioStreamPlayer = null


func _ready() -> void:
	DayNightSwitch.disable(self)
	randomize()
	if level_data == null or director == null:
		push_error("StopwatchLevel '%s': falta o StopwatchLevelData ou o Diretor." % name)
		return
	director.level_data = level_data
	director.customer_served.connect(_on_customer_served.unbind(3))
	director.customer_furious.connect(_on_customer_furious)
	director.wave_finished.connect(_on_wave_finished)
	if chef:
		chef.health_changed.connect(_on_chef_health_changed)
		if hide_chef_mana:
			_hide_mana()
	if hud:
		hud.restart_requested.connect(restart)
		hud.exit_requested.connect(back_to_map)
		hud.setup_stopwatch(level_data.display_name, level_data)
	_ensure_pause_menu()
	_setup_bgm()

	if fire_wall:
		fire_wall.ignite()
	await get_tree().create_timer(start_delay).timeout
	if _finished:
		return
	_running = true
	director.start()
	level_started.emit()
	_play_bgm()


func _process(delta: float) -> void:
	if not _running or _finished:
		return
	elapsed += delta
	if hud:
		hud.set_elapsed(elapsed)
		hud.set_progress(get_served(), get_correct(), level_data.total_customers, elapsed)


func get_served() -> int:
	return director.served_count if director else 0


func get_correct() -> int:
	return director.correct_count if director else 0


func get_stars() -> int:
	return level_data.stars_for_result(elapsed, get_correct()) if level_data else 0


func is_running() -> bool:
	return _running and not _finished


func is_finished() -> bool:
	return _finished


func finish(completed: bool, reason: String = "") -> void:
	if _finished:
		return
	_finished = true
	_running = false
	director.stop()
	director.dismiss_all()
	var stars: int = get_stars() if completed else 0
	var success: bool = stars > 0
	if success:
		LevelSelectMap.record_result(level_data.level_id, stars)
	if hud:
		if completed and not success:
			reason = "Faltaram pedidos certos para a 1ª estrela."
		hud.show_end(success, reason, {
			"stars": stars,
			"max_stars": level_data.get_max_stars(),
			"served": get_served(),
			"correct": get_correct(),
			"total": level_data.total_customers,
			"time": elapsed,
		})
	level_finished.emit(success, stars)
	_stop_bgm()
	if pause_on_end:
		get_tree().create_timer(pause_delay, true).timeout.connect(func() -> void:
			if _finished:
				get_tree().paused = true)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func back_to_map() -> void:
	get_tree().paused = false
	LevelSelectMap.change_scene(get_tree(), map_scene)


# --- Sinais --------------------------------------------------------------------

func _on_customer_served() -> void:
	if hud:
		hud.set_progress(get_served(), get_correct(), level_data.total_customers, elapsed)


func _on_customer_furious(customer: Customer, _times: int) -> void:
	FloatingText.spawn(customer.get_parent(), customer.global_position + Vector2(0, -40), "RAIVA PURA!", Color(1.0, 0.4, 0.35))


func _on_wave_finished() -> void:
	finish(true, "Todos os clientes atendidos!")


func _on_chef_health_changed(current: int, _maximum: int) -> void:
	if current > 0 or _finished or _death_pending:
		return
	_death_pending = true
	if not level_data.fail_on_chef_death:
		get_tree().create_timer(revive_delay).timeout.connect(_revive_chef)
		return
	get_tree().create_timer(death_delay).timeout.connect(func() -> void:
		_death_pending = false
		if chef and chef.is_dead():
			finish(false, "O chef caiu!"))


func _revive_chef() -> void:
	_death_pending = false
	if _finished or chef == null or not chef.is_dead():
		return
	chef.heal_full()
	FloatingText.spawn(chef.get_parent(), chef.global_position + Vector2(0, -30), "De volta!", Color(0.6, 1.0, 0.7))


# --- Apoio ---------------------------------------------------------------------

func _hide_mana() -> void:
	var mana_row: CanvasItem = chef.get_node_or_null("HudChef/Coluna/Mana") as CanvasItem
	if mana_row:
		mana_row.visible = false


func _ensure_pause_menu() -> void:
	if get_tree().root.has_node("PauseMenu"):
		return
	var pause_scene: PackedScene = load("res://menus/pause/pause_menu.tscn")
	if pause_scene:
		get_tree().root.call_deferred("add_child", pause_scene.instantiate())


func _setup_bgm() -> void:
	if bgm == null:
		return
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.stream = bgm
	_bgm_player.bus = &"Music"
	_bgm_player.volume_db = -4.0
	add_child(_bgm_player)


func _play_bgm() -> void:
	if _bgm_player and not _bgm_player.playing:
		_bgm_player.play()


func _stop_bgm() -> void:
	if _bgm_player and _bgm_player.playing:
		var fade := create_tween()
		fade.tween_property(_bgm_player, "volume_db", -40.0, 0.6)
		fade.tween_callback(_bgm_player.stop)
