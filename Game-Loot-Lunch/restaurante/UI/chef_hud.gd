extends CanvasLayer
class_name ChefHUD
## HUD do chef (canto superior esquerdo): caveiras de vida + mana + dinheiro.
##
## Só LIGA fios — quem desenha é SkullHealthBar, ManaBar e MoneyCounter:
##   chef.health_changed(atual, máximo)  -> Vida.set_health
##   ManaComponent.mana_changed          -> Mana.set_mana
##   ManaComponent.insufficient          -> Mana.shake (tentou usar sem mana)
##   WalletComponent.amount_changed      -> Dinheiro.set_amount
##
## Uso: instancie `hud_chef.tscn` como filho do Chef (já está em chef.tscn).
## Como é CanvasLayer, fica fixo na tela mesmo sendo filho do chef.


## Quem o HUD mostra. Vazio = o nó pai.
@export var chef: Node


@onready var health_bar: SkullHealthBar = %Vida
@onready var money_counter: MoneyCounter = %Dinheiro
@onready var mana_bar: ManaBar = get_node_or_null("%Mana")


func _ready() -> void:
	if chef == null:
		chef = get_parent()
	if chef == null:
		return

	# Vida (qualquer nó com hp / max_hp / health_changed serve).
	if chef.has_signal(&"health_changed"):
		chef.connect(&"health_changed", health_bar.set_health)
		health_bar.set_health(int(chef.get(&"hp")), int(chef.get(&"max_hp")))
	else:
		health_bar.hide()

	# Mana (barras das habilidades).
	var mana: ManaComponent = ManaComponent.find_in(chef)
	if mana_bar:
		if mana:
			mana.mana_changed.connect(mana_bar.set_mana)
			mana.insufficient.connect(_on_mana_insufficient.unbind(2))
			mana_bar.set_mana(mana.mana, mana.max_mana)
		else:
			mana_bar.hide()

	# Dinheiro.
	var wallet: WalletComponent = WalletComponent.find_in(chef)
	if wallet:
		wallet.amount_changed.connect(_on_amount_changed)
		money_counter.set_amount(wallet.amount, false)
	else:
		money_counter.hide()


func _on_amount_changed(new_amount: int, _delta: int) -> void:
	money_counter.set_amount(new_amount)


func _on_mana_insufficient() -> void:
	mana_bar.shake()
