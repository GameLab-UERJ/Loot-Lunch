extends Node
class_name WalletComponent
## CARTEIRA: guarda quanto dinheiro o dono tem. Não sabe de onde o dinheiro vem
## (pedido, gorjeta, baú...) nem quem mostra na tela — só guarda e avisa.
##
## Reutilizável: chef, 2º jogador, caixa registradora, cofre da loja...
##
## Uso:
##   WalletComponent.find_in(chef).add(10)
##   if wallet.try_spend(5): ...
## Quem quer mostrar o valor (HUD) conecta em `amount_changed`.


signal amount_changed(new_amount: int, delta: int)


## Nome da moeda (aparece nos textos "+10 Almas"). Troque aqui para renomear o dinheiro.
@export var currency_name: String = "Almas"
@export var starting_amount: int = 0
## Grupo em que a carteira se registra. Serve de "carteira padrão" quando
## ninguém sabe quem entregou o pedido (ex.: item que caiu de uma bancada).
@export var group_name: StringName = &"carteiras"


var amount: int = 0


## Encontra o WalletComponent filho direto de um nó (ex.: o Chef). Retorna null se não houver.
static func find_in(node: Node) -> WalletComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is WalletComponent:
			return child
	return null


## Primeira carteira registrada no grupo (fallback quando não se sabe o dono).
static func find_default(tree: SceneTree, group: StringName = &"carteiras") -> WalletComponent:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(group):
		if node is WalletComponent:
			return node
	return null


func _ready() -> void:
	if group_name != &"":
		add_to_group(group_name)
	amount = starting_amount
	amount_changed.emit(amount, 0)


func add(value: int) -> void:
	if value == 0:
		return
	amount += value
	amount_changed.emit(amount, value)


func can_afford(value: int) -> bool:
	return amount >= value


## Gasta se tiver saldo. Retorna se conseguiu.
func try_spend(value: int) -> bool:
	if value < 0 or not can_afford(value):
		return false
	add(-value)
	return true


## "10 Almas"
func format(value: int) -> String:
	return "%d %s" % [value, currency_name]
