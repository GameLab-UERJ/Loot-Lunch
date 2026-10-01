extends Node
class_name PatienceAbilityTrigger
## Liga a PACIÊNCIA do cliente às MAGIAS dele: quando a barra CAI abaixo de um limite,
## o cliente lança a magia daquele nível.
##
##   limites padrão:  90% -> magia 1   |   50% -> magia 2   |   20% -> magia 3
##
## Não sabe o que cada magia faz: só chama `CustomerAbilityCaster.cast_for_patience_level`.
## Não sabe o que é a barra: só escuta `PatienceComponent.patience_changed`.
##
## Uso: coloque como filho do cliente (ao lado de "Habilidades"). O `PatienceComponent`
## pode nascer depois (o Customer cria ele quando chega na fila): este nó espera ele
## aparecer e se conecta sozinho.
##
## Se a magia não sair na hora (o cliente ainda está lançando a anterior, ou o chef está
## engolido/morto), tenta de novo a cada frame até sair — sem empilhar: se o próximo
## limite chegar antes, vale o mais novo.
## Se a paciência voltar a encher (reiniciou), os limites são rearmados.


## Passou um limite. `cast_ok` = a magia saiu na hora (false = vai tentar de novo).
signal threshold_reached(level: int, ratio: float, cast_ok: bool)
## A magia do nível `level` finalmente saiu (na hora ou depois de tentar de novo).
signal ability_triggered(level: int)


## Limites da barra (0..1), do MAIOR para o MENOR. O 1º lança a magia 1, o 2º a magia 2...
@export var thresholds: Array[float] = [0.9, 0.5, 0.2]
@export var enabled: bool = true
## Cliente dono da paciência. Vazio = o pai deste nó.
@export var customer: Node
## Nó com as magias. Vazio = filho "Habilidades" do cliente.
@export var caster: CustomerAbilityCaster
## Nome do nó de paciência dentro do cliente.
@export var patience_node_name: StringName = &"PatienceComponent"
@export var debug_print: bool = false


var patience: PatienceComponent = null
## Quantos limites já passaram (0 = nenhum).
var levels_reached: int = 0
## Nível esperando para lançar (a magia não saiu na hora). 0 = nenhum.
var pending_level: int = 0


func _ready() -> void:
	if customer == null:
		customer = get_parent()
	if caster == null and customer:
		caster = customer.get_node_or_null("Habilidades") as CustomerAbilityCaster
	if caster == null:
		push_warning("PatienceAbilityTrigger (%s): nenhum CustomerAbilityCaster ('Habilidades')." % _customer_name())


func _process(_delta: float) -> void:
	if patience == null or not is_instance_valid(patience):
		_try_connect()
	if pending_level > 0 and enabled:
		if _cast(pending_level):
			pending_level = 0


## Para de lançar (ex.: o cliente foi atendido e vai embora).
func stop() -> void:
	enabled = false
	pending_level = 0


## Rearma todos os limites (ex.: a paciência recomeçou do zero).
func reset() -> void:
	levels_reached = 0
	pending_level = 0


func get_level_count() -> int:
	return thresholds.size()


func _try_connect() -> void:
	if customer == null:
		return
	var found := customer.get_node_or_null(NodePath(patience_node_name)) as PatienceComponent
	if found == null:
		return
	patience = found
	if not patience.patience_changed.is_connected(_on_patience_changed):
		patience.patience_changed.connect(_on_patience_changed)


func _on_patience_changed(ratio: float) -> void:
	if not enabled or thresholds.is_empty():
		return
	# Encheu de novo acima do 1º limite: recomeçou.
	if levels_reached > 0 and ratio > thresholds[0]:
		reset()
	while levels_reached < thresholds.size() and ratio <= thresholds[levels_reached]:
		levels_reached += 1
		var ok: bool = _cast(levels_reached)
		pending_level = 0 if ok else levels_reached
		threshold_reached.emit(levels_reached, ratio, ok)
		if debug_print:
			print("[Paciência] %s caiu para %d%% -> magia %d %s" % [_customer_name(),
				roundi(ratio * 100.0), levels_reached, "saiu" if ok else "vai tentar de novo"])


func _cast(level: int) -> bool:
	if caster == null:
		return false
	if caster.cast_for_patience_level(level):
		ability_triggered.emit(level)
		return true
	return false


func _customer_name() -> String:
	return String(customer.name) if customer else String(name)
