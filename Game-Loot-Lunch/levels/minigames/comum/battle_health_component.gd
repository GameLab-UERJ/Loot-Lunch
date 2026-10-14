extends Node
class_name BattleHealthComponent
## VIDA de quem luta na batalha por turnos (formiga, chef, futuros chefões).
## Só guarda, tira, cura e avisa — não sabe quem desenha a barra nem quem bate.
##
##   health.damage(5)        -> health_changed, e `died` se zerar
##   health.heal(4)
##   health.get_ratio()      -> 0..1 (a habilidade Devorar usa: só abaixo de 20%)
##
## Mesmo contrato de sinal do Chef (`health_changed(atual, máximo)`), então o
## SkullHealthBar / ChefHUD do restaurante funcionam ligados nele.


signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died


@export_range(1, 999) var max_hp: int = 20
## Ligado = não toma dano (ex.: está dentro do buraco, pulou o terremoto).
@export var invulnerable: bool = false


var hp: int = 0


func _ready() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)


static func find_in(node: Node) -> BattleHealthComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is BattleHealthComponent:
			return child
	return null


func damage(amount: int) -> int:
	if amount <= 0 or invulnerable or is_dead():
		return 0
	var dealt: int = mini(amount, hp)
	hp -= dealt
	damaged.emit(dealt)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()
	return dealt


func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var gained: int = mini(amount, max_hp - hp)
	hp += gained
	if gained > 0:
		healed.emit(gained)
		health_changed.emit(hp, max_hp)
	return gained


func kill() -> void:
	if not is_dead():
		damage(hp)


func is_dead() -> bool:
	return hp <= 0


func get_ratio() -> float:
	return float(hp) / float(maxi(max_hp, 1))
