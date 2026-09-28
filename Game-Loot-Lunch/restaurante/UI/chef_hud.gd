extends CanvasLayer
class_name ChefHUD
## HUD do chef (canto superior esquerdo): caveiras de vida + dinheiro.
##
## Só LIGA fios — quem desenha é SkullHealthBar e MoneyCounter:
##   chef.health_changed(atual, máximo) -> Vida.set_health
##   WalletComponent.amount_changed     -> Dinheiro.set_amount
##
## Uso: instancie `hud_chef.tscn` como filho do Chef (já está em chef.tscn).
## Como é CanvasLayer, fica fixo na tela mesmo sendo filho do chef.


## Quem o HUD mostra. Vazio = o nó pai.
@export var chef: Node


@onready var health_bar: SkullHealthBar = %Vida
@onready var money_counter: MoneyCounter = %Dinheiro


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

	# Dinheiro.
	var wallet: WalletComponent = WalletComponent.find_in(chef)
	if wallet:
		wallet.amount_changed.connect(_on_amount_changed)
		money_counter.set_amount(wallet.amount, false)
	else:
		money_counter.hide()


func _on_amount_changed(new_amount: int, _delta: int) -> void:
	money_counter.set_amount(new_amount)
