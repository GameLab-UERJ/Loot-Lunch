extends Battler
class_name FormigaBattler
## Uma TANAJURA da Fase 3 (inimiga da batalha).
##
## As 5 lutam AO MESMO TEMPO: cada uma tem o seu BattleWaitComponent (tempo de espera).
## Quando a espera enche, a batalha mostra o "!" em cima dela e ela ataca. Algumas são
## mais rápidas (espera menor) — isso NÃO aparece na tela: é o jogador que percebe.
##
## Escolhe o ataque do turno entre as FormigaSkill filhas (sorteio por `weight`, sem
## repetir o mesmo duas vezes seguidas). Arte: tanajura_L_6F.png (olha para a ESQUERDA,
## `art_faces_left`). Ao morrer some e deixa o DROP (dropTanajura.png) no lugar.


signal defeated(ant: FormigaBattler)
## Clicaram nela (para escolher o alvo).
signal clicked(ant: FormigaBattler)


@export var hp_bar: ProgressBarComponent
@export var art_faces_left: bool = true
## O drop que fica no chão quando ela cai (bunda de tanajura).
@export var drop_texture: Texture2D
@export var drop_scale: Vector2 = Vector2(2, 2)
## "!" em cima da cabeça antes de atacar e estrelinhas quando atordoada.
@export var alert_anim: SheetAnimation
@export var dizzy_anim: SheetAnimation
## Altura da cabeça (onde ficam o "!" e as estrelas).
@export var head_offset: Vector2 = Vector2(4, -46)
@export var click_target: ClickTargetComponent


## 0..4: qual formiga da fila é (as últimas ficam mais espertas).
var level: int = 0
## Foi devorada (Devorar) em vez de nocauteada.
var devoured: bool = false
## O drop no chão depois de cair (null enquanto viva).
var drop: Sprite2D
var _last_skill: FormigaSkill = null
var _alert: AnimatedSprite2D
var _dizzy: AnimatedSprite2D


@onready var skills: Array[FormigaSkill] = FormigaSkill.find_all_in(self)


func _ready() -> void:
	super._ready()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(func() -> void: defeated.emit(self))
	_on_health_changed(health.hp, health.max_hp)
	if wait:
		wait.stun_changed.connect(_on_stun_changed)
	if click_target:
		click_target.clicked.connect(func() -> void: clicked.emit(self))


func choose_skill() -> FormigaSkill:
	var pool: Array[FormigaSkill] = []
	for skill in skills:
		if skill.enabled and (skill != _last_skill or skills.size() == 1):
			pool.append(skill)
	if pool.is_empty():
		return null
	var total: float = 0.0
	for skill in pool:
		total += skill.weight
	var roll: float = randf() * total
	for skill in pool:
		roll -= skill.weight
		if roll <= 0.0:
			_last_skill = skill
			return skill
	_last_skill = pool.back()
	return _last_skill


## "!" piscando em cima da cabeça (vai atacar).
func show_alert(value: bool) -> void:
	if value and _alert == null and alert_anim:
		_alert = alert_anim.create_sprite()
		_alert.position = head_offset + Vector2(0, -22)
		add_child(_alert)
	elif not value and _alert:
		_alert.queue_free()
		_alert = null


## Atordoada: a espera para de encher e aparecem as estrelinhas.
func daze(seconds: float) -> void:
	if wait and not is_dead():
		wait.stun(seconds)


func set_targetable(value: bool) -> void:
	if click_target:
		click_target.enabled = value


## Nocaute: vira de barriga para cima, some e deixa o drop.
func play_death() -> void:
	show_alert(false)
	_on_stun_changed(false)
	set_targetable(false)
	if hp_bar:
		hp_bar.set_bar_visible(false)
	if sprite and not devoured:
		var tween := create_tween()
		tween.tween_property(sprite, "scale:y", -absf(sprite.scale.y), 0.15)
		tween.parallel().tween_property(sprite, "position:y", -10.0, 0.15)
		tween.tween_property(sprite, "position:y", 0.0, 0.15).set_ease(Tween.EASE_IN)
		tween.tween_interval(0.2)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3)
		await tween.finished
	if sprite:
		sprite.hide()
	_spawn_drop()


func hide_drop() -> void:
	if drop:
		drop.hide()


func _spawn_drop() -> void:
	if drop_texture == null or drop:
		return
	drop = Sprite2D.new()
	drop.texture = drop_texture
	drop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(drop)
	drop.position = Vector2(0, 6)
	drop.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(drop, "scale", drop_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _on_stun_changed(stunned: bool) -> void:
	if stunned and _dizzy == null and dizzy_anim:
		_dizzy = dizzy_anim.create_sprite()
		_dizzy.position = head_offset + Vector2(0, 8)
		add_child(_dizzy)
	elif not stunned and _dizzy:
		_dizzy.queue_free()
		_dizzy = null


func _on_health_changed(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.set_bar_visible(current > 0)
		hp_bar.set_progress(float(current) / float(maxi(maximum, 1)))
		# Vermelha abaixo de 20%: hora de DEVORAR.
		hp_bar.fill_color = Color(0.9, 0.3, 0.25) if health.get_ratio() < 0.2 \
			else Color(0.45, 0.85, 0.35)
		hp_bar.queue_redraw()
