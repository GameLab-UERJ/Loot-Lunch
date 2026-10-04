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
## Chefe (a Rainha): a batalha acaba quando ele cai.
@export var is_boss: bool = false
## Nome na luta ("Tanajura 1", "Guardiã 2"...).
@export var name_prefix: String = "Tanajura"
## GUARDIÃ: enquanto houver uma viva, o chefe não leva dano nem pode ser alvo.
@export var protects_boss: bool = false
## Cor do pisca-pisca da FÚRIA (a Rainha voando). A Guardiã usa uma mais fraca para a
## armadura continuar aparecendo.
@export var rage_tint: Color = Color(1.6, 0.55, 0.5)


## 0..4: qual formiga da fila é (as últimas ficam mais espertas).
var level: int = 0
## Foi devorada pelo CHEF (Devorar): a bunda fica para a farofa.
var devoured: bool = false
## Foi devorada pela RAINHA: some sem deixar drop.
var eaten: bool = false
## Vaga da formação onde ela fica (-1 = nenhuma).
var slot_index: int = -1
## Quantas vezes já agiu (para o tempo de recarga das habilidades).
var turns_taken: int = 0
## Fase da formiga (as habilidades filtram por `FormigaSkill.phases`). A Rainha vai para
## 1 na fase final; as outras ficam sempre em 0.
var phase: int = 0
var _enraged: bool = false
var _rage_tween: Tween
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


## Sorteia o ataque do turno. Primeiro vê se alguma habilidade EXIGE sair agora
## (`has_priority`, ex.: Devorar e Conjurar da Rainha); senão sorteia por `weight` entre as
## que podem (`can_use`), fora da recarga, sem repetir a última.
func choose_skill(battle: TurnBattle = null) -> FormigaSkill:
	for skill in skills:
		if skill.enabled and skill.allowed_for(self) and skill.has_priority(battle, self) and skill.can_use(battle, self):
			return _pick(skill)
	var pool: Array[FormigaSkill] = []
	for skill in skills:
		if not skill.enabled or not skill.allowed_for(self) or not skill.can_use(battle, self) \
				or skill.is_cooling_down(self):
			continue
		if skill == _last_skill and skills.size() > 1:
			continue
		pool.append(skill)
	if pool.is_empty() and _last_skill and _last_skill.allowed_for(self) and _last_skill.can_use(battle, self):
		pool.append(_last_skill)
	if pool.is_empty():
		return null
	var total: float = 0.0
	for skill in pool:
		total += skill.weight
	var roll: float = randf() * total
	for skill in pool:
		roll -= skill.weight
		if roll <= 0.0:
			return _pick(skill)
	return _pick(pool.back())


## Habilidade de PRIORIDADE MÁXIMA pronta para sair agora (sem esperar a barra), ou null.
func interrupting_skill(battle: TurnBattle) -> FormigaSkill:
	for skill in skills:
		if skill.enabled and skill.interrupts and skill.has_priority(battle, self) and skill.can_use(battle, self):
			return skill
	return null


## Marca a habilidade como a escolhida deste turno (recarga, "não repetir").
func use_skill(skill: FormigaSkill) -> FormigaSkill:
	return _pick(skill)


func _pick(skill: FormigaSkill) -> FormigaSkill:
	_last_skill = skill
	skill.last_used_turn = turns_taken
	turns_taken += 1
	return skill


## Fúria (a Rainha voando): pisca vermelho enquanto estiver ligada.
func set_enraged(value: bool) -> void:
	if value == _enraged or sprite == null:
		return
	_enraged = value
	if _rage_tween:
		_rage_tween.kill()
		_rage_tween = null
	if value and not is_dead():
		_rage_tween = create_tween().set_loops()
		_rage_tween.tween_property(sprite, "self_modulate", rage_tint, 0.3)
		_rage_tween.tween_property(sprite, "self_modulate", Color(1.15, 0.85, 0.85), 0.3)
	else:
		sprite.self_modulate = Color.WHITE


func is_enraged() -> bool:
	return _enraged


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


## Pode ser escolhida como alvo agora? (viva e sem proteção).
func can_be_targeted() -> bool:
	return not is_dead() and not is_protected()


func set_targetable(value: bool) -> void:
	if click_target:
		click_target.enabled = value


## Nocaute: vira de barriga para cima, some e deixa o drop.
func play_death() -> void:
	set_enraged(false)
	show_alert(false)
	_on_stun_changed(false)
	set_targetable(false)
	if hp_bar:
		hp_bar.set_bar_visible(false)
	if sprite and not devoured and not eaten:
		var tween := create_tween()
		tween.tween_property(sprite, "scale:y", -absf(sprite.scale.y), 0.15)
		tween.parallel().tween_property(sprite, "position:y", -10.0, 0.15)
		tween.tween_property(sprite, "position:y", 0.0, 0.15).set_ease(Tween.EASE_IN)
		tween.tween_interval(0.2)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3)
		await tween.finished
	if sprite:
		sprite.hide()
	if not eaten:
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
