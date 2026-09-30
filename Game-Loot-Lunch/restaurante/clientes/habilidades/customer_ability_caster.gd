extends Node
class_name CustomerAbilityCaster
## Nó "Habilidades" do cliente: guarda as magias dele EM ORDEM e lança quando mandarem.
##
##   Patolino
##   └── Habilidades (CustomerAbilityCaster)
##       ├── Quack          magia 1
##       ├── Ovo            magia 2
##       └── PatoDevorador  magia 3 (ultimate / summon)
##
## A ordem dos filhos É a ordem das magias. Quem decide QUANDO lançar é outro sistema
## (a paciência do cliente, um teste, um tutorial...). Ele só chama:
##     cast(0)                          -> primeira magia
##     cast_for_patience_level(2)       -> perdeu o 2º nível de paciência = 2ª magia
##     cast_by_name(&"Ovo")
## O caster não sabe o que cada magia faz.


signal ability_cast(index: int, ability: CustomerAbility)


@export var enabled: bool = true


## As magias, na ordem da árvore.
func get_abilities() -> Array[CustomerAbility]:
	var found: Array[CustomerAbility] = []
	for child in get_children():
		if child is CustomerAbility:
			found.append(child)
	return found


func get_ability(index: int) -> CustomerAbility:
	var abilities: Array[CustomerAbility] = get_abilities()
	if index < 0 or index >= abilities.size():
		return null
	return abilities[index]


## Lança a magia de índice `index` (0 = primeira). Retorna true se saiu.
func cast(index: int, target: Node2D = null) -> bool:
	if not enabled:
		return false
	var ability: CustomerAbility = get_ability(index)
	if ability == null or not ability.cast(target):
		return false
	ability_cast.emit(index, ability)
	return true


func cast_by_name(ability_name: StringName, target: Node2D = null) -> bool:
	var abilities: Array[CustomerAbility] = get_abilities()
	for i in abilities.size():
		if abilities[i].name == ability_name:
			return cast(i, target)
	return false


## Gancho da PACIÊNCIA: perdeu o nível `level` (1, 2, 3...) -> lança a magia daquele nível.
## Níveis além do número de magias repetem a última (a ultimate).
func cast_for_patience_level(level: int, target: Node2D = null) -> bool:
	var count: int = get_abilities().size()
	if count == 0 or level <= 0:
		return false
	return cast(mini(level, count) - 1, target)


## Alguma magia está sendo preparada/lançada agora?
func is_casting() -> bool:
	for ability in get_abilities():
		if ability.is_busy():
			return true
	return false


## Cancela o que estiver preparando (ex.: o cliente foi atendido e vai embora).
func interrupt_all() -> void:
	for ability in get_abilities():
		ability.interrupt()
