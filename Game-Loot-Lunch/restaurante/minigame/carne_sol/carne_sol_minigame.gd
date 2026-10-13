extends BossMinigame
class_name CarneSolMinigame
## FASE 1 da boss fight do VIP: A CARNE DE SOL ("Conjuração Solar").
##
## MULTITAREFA:
##   - Segura ESPAÇO -> o chef canaliza o MINI-SOL e a barra verde (TimingGauge) sobe.
##   - Solta ESPAÇO  -> tira a carne do sol e o ponto é avaliado:
##         antes da zona dourada = "Carne Suada"   (falha)
##         dentro da zona        = "Carne de Sol Perfeita" (sucesso)
##         depois / barra cheia  = "Carne Carbonizada" (falha)
##   - Enquanto canaliza, o sol solta FAGULHAS em arco. CLIQUE nelas antes que caiam
##     na carne. Cada fagulha que encosta empurra o ponto (+`burn_penalty`) e deixa uma
##     marca; `max_burns` marcas = carbonizou.
##
## Soltar logo no começo (abaixo do `min_commit` do .tres) é só uma pausa, não conta.
##
## Peças (todas reaproveitáveis):
##   TargetMeterComponent (Medidor) + TargetMeterProfile (dados/carne_sol_ponto.tres)
##   TimingGauge (Barra) | MiniSol + FagulhaSolar | SheetSprite (chef) | FloatingText


## Quadros de carne_sol_estados.png (na ordem do sheet).
enum MeatLook { CRUA, SUADA, PERFEITA, CARBONIZADA }


@export var heat_action: StringName = &"chef_pick_drop"
@export var meter: TargetMeterComponent
@export var mini_sol: MiniSol
## Sprite da carne (carne_sol_estados.png com hframes = 4).
@export var meat: Sprite2D
## Onde as marcas de queimado ficam (filho da carne, para acompanhar a escala).
@export var burn_marks: Node2D
@export var burn_mark_texture: Texture2D
## Sprite do chef (de onde sai o feixe de magia).
@export var chef_sprite: Node2D
## Linha do feixe chef -> sol (Line2D).
@export var beam: Line2D

@export_group("Fagulhas")
## Quanto cada fagulha que cai na carne empurra o ponto.
@export_range(0.0, 0.5, 0.01) var burn_penalty: float = 0.08
## Fagulhas na carne até carbonizar de vez.
@export_range(1, 10) var max_burns: int = 3
## Cada queimadura tira isto da qualidade final (mesmo acertando o ponto).
@export_range(0.0, 0.5, 0.01) var burn_quality_loss: float = 0.15

@export_group("Visual")
## A partir daqui a carne já aparece "suando" (só visual).
@export_range(0.0, 1.0, 0.01) var sweaty_from: float = 0.3


var burns: int = 0
var sparks_caught: int = 0
var _holding: bool = false
var _clock: float = 0.0
var _meat_base_position: Vector2


func _ready() -> void:
	super._ready()
	mini_sol.spark_spawned.connect(_on_spark_spawned)
	meter.ruined.connect(_on_meter_ruined)
	meter.value_changed.connect(_on_meter_value_changed.unbind(1))
	_meat_base_position = meat.position
	if beam:
		beam.hide()
	_update_meat()


func _on_begin() -> void:
	meter.reset()
	meter.running = true
	popup(meat.global_position + Vector2(0, -40), "Segure ESPAÇO!", Color(1.0, 0.85, 0.4))


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not running:
		return
	if event.is_action_pressed(heat_action) and not event.is_echo():
		_set_holding(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_released(heat_action) and _holding:
		_set_holding(false)
		get_viewport().set_input_as_handled()
		if not meter.is_below_commit():
			_take_out()


func _process(delta: float) -> void:
	_clock += delta
	mini_sol.intensity = meter.value
	_update_beam()


func _set_holding(value: bool) -> void:
	_holding = value
	meter.set_active(value)
	mini_sol.set_channeling(value)
	if beam:
		beam.visible = value


## Soltou o ESPAÇO: tira a carne do sol e avalia o ponto.
func _take_out() -> void:
	var label: String = meter.get_label()
	if meter.is_perfect():
		var quality: float = clampf(meter.get_quality() - burns * burn_quality_loss, 0.1, 1.0)
		_end(true, label, quality)
	else:
		_end(false, label, 0.0)


func _end(success: bool, label: String, quality: float) -> void:
	_update_meat()
	popup(meat.global_position + Vector2(0, -36), label,
		Color(0.55, 1.0, 0.55) if success else Color(1.0, 0.45, 0.45))
	finish(success, {
		"label": label,
		"quality": quality,
		"stars": BossMinigame.stars_for(quality) if success else 0,
		"burns": burns,
		"sparks_caught": sparks_caught,
	})


func _on_finish(_success: bool) -> void:
	_set_holding(false)
	meter.running = false
	mini_sol.spawn_enabled = false
	var container: Node = mini_sol.sparks_container if mini_sol.sparks_container else self
	for child in container.get_children():
		if child is FagulhaSolar:
			child.queue_free()


# --- Fagulhas ------------------------------------------------------------------

func _on_spark_spawned(spark: FagulhaSolar) -> void:
	spark.landed.connect(_on_spark_landed)
	spark.caught.connect(_on_spark_caught)


func _on_spark_caught(spark: FagulhaSolar) -> void:
	sparks_caught += 1
	popup(spark.global_position, "Pegou!", Color(1.0, 0.9, 0.5))


func _on_spark_landed(spark: FagulhaSolar) -> void:
	if not running:
		return
	burns += 1
	_add_burn_mark(spark.global_position)
	_shake_meat()
	popup(spark.global_position + Vector2(0, -10), "Queimou! %d/%d" % [burns, max_burns],
		Color(1.0, 0.45, 0.3))
	if burns >= max_burns:
		_end(false, meter.profile.over_label, 0.0)
		return
	meter.add(burn_penalty)


func _add_burn_mark(at: Vector2) -> void:
	if burn_marks == null or burn_mark_texture == null:
		return
	var mark := Sprite2D.new()
	mark.texture = burn_mark_texture
	mark.hframes = maxi(burn_mark_texture.get_width() / maxi(burn_mark_texture.get_height(), 1), 1)
	mark.scale = Vector2(0.25, 0.25)
	mark.modulate = Color(1, 1, 1, 0.85)
	burn_marks.add_child(mark)
	# A marca fica em cima da carne, mesmo que a fagulha tenha caído na borda.
	var local: Vector2 = burn_marks.to_local(at)
	mark.position = Vector2(clampf(local.x, -9.0, 9.0), clampf(local.y, -4.0, 4.0))


func _shake_meat() -> void:
	var tween := create_tween()
	for i in 4:
		var side: float = 3.0 if i % 2 == 0 else -3.0
		tween.tween_property(meat, "position", _meat_base_position + Vector2(side, 0), 0.04)
	tween.tween_property(meat, "position", _meat_base_position, 0.04)


# --- Visual --------------------------------------------------------------------

func _on_meter_value_changed() -> void:
	_update_meat()


func _on_meter_ruined() -> void:
	if running:
		_end(false, meter.profile.over_label, 0.0)


func _update_meat() -> void:
	if meat == null or meter == null:
		return
	var look: MeatLook = MeatLook.CRUA
	match meter.get_zone():
		TargetMeterProfile.Zone.PERFECT:
			look = MeatLook.PERFEITA
		TargetMeterProfile.Zone.OVER:
			look = MeatLook.CARBONIZADA
		_:
			if meter.value >= sweaty_from:
				look = MeatLook.SUADA
	if burns >= max_burns:
		look = MeatLook.CARBONIZADA
	meat.frame = look


func _update_beam() -> void:
	if beam == null or not beam.visible or chef_sprite == null:
		return
	var from: Vector2 = beam.to_local(chef_sprite.global_position + Vector2(8, -14))
	var to: Vector2 = beam.to_local(mini_sol.global_position)
	var points := PackedVector2Array()
	var normal: Vector2 = (to - from).orthogonal().normalized()
	for i in 9:
		var t: float = i / 8.0
		var wave: float = sin(t * 9.0 - _clock * 18.0) * 3.0 * sin(t * PI)
		points.append(from.lerp(to, t) + normal * wave)
	beam.points = points
