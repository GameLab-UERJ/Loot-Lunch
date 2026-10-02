extends Battler
class_name FormigaBattler
## Uma TANAJURA da Fase 3 (inimiga da batalha por turnos).
##
## Escolhe o ataque do turno entre as FormigaSkill filhas (sorteio por `weight`, sem
## repetir o mesmo duas vezes seguidas). A barra de vida em cima dela é um
## ProgressBarComponent do restaurante. Arte: Ants.png (tanajura vermelha), que olha
## para a ESQUERDA (`art_faces_left`).


signal defeated(ant: FormigaBattler)


@export var hp_bar: ProgressBarComponent
@export var art_faces_left: bool = true


## 0..4: qual formiga da fila é (as últimas ficam mais espertas).
var level: int = 0
## Foi devorada (Devorar) em vez de nocauteada.
var devoured: bool = false
var _last_skill: FormigaSkill = null


@onready var skills: Array[FormigaSkill] = FormigaSkill.find_all_in(self)


func _ready() -> void:
	super._ready()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(func() -> void: defeated.emit(self))
	_on_health_changed(health.hp, health.max_hp)


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


## Animação de nocaute (vira de barriga para cima e escurece).
func play_death() -> void:
	if hp_bar:
		hp_bar.set_bar_visible(false)
	if sprite:
		await sprite.play_once(&"morrer")
		create_tween().tween_property(sprite, "modulate", Color(0.6, 0.55, 0.55), 0.3)


func _on_health_changed(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.set_bar_visible(current > 0)
		hp_bar.set_progress(float(current) / float(maxi(maximum, 1)))
		# Vermelha abaixo de 20%: hora de DEVORAR.
		hp_bar.fill_color = Color(0.9, 0.3, 0.25) if health.get_ratio() < 0.2 \
			else Color(0.45, 0.85, 0.35)
		hp_bar.queue_redraw()
