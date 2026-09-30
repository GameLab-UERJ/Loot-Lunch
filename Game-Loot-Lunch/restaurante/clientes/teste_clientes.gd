extends Node2D
## Cena de teste dos 3 CLIENTES JUNTOS (Patolino, Mandy e Johnny) contra o chef.
##
##   1 2 3 = Patolino: quack (derruba o item) | ovo | pato devorador
##   4 5 6 = Mandy:    símbolo de bruxaria    | caveira de fogo | demoninho
##   7 8 9 = Johnny:   raio                   | esfera de raio  | raio supremo (+ nuvem)
##   0     = paciência de TODOS cai 1 nível (cada um solta a magia do nível)
##   G = espetinho na mão | H = cura / revive | R = pega/larga | Espaço = dash
##   ◀ ▶ alternados = escapar da barriga do pato
##
## Dá para misturar: ex. 7 (raio atordoa) e logo 5 (caveira acerta o chef parado),
## ou 6 (demoninho grudado) com 3/9 no mapa para ver o pato e a nuvem dançando.


@export var item_scene: PackedScene
## Item que o G coloca na mão do chef.
@export var give_item: Resource


## Tecla -> [nome do cliente na cena, índice da magia (0 = primeira)]
const KEYS: Dictionary = {
	KEY_1: [&"Patolino", 0], KEY_2: [&"Patolino", 1], KEY_3: [&"Patolino", 2],
	KEY_4: [&"Mandy", 0], KEY_5: [&"Mandy", 1], KEY_6: [&"Mandy", 2],
	KEY_7: [&"Johnny", 0], KEY_8: [&"Johnny", 1], KEY_9: [&"Johnny", 2],
}


var _patience_level: int = 0


@onready var chef: Chef = $Chef
@onready var items_container: Node = $ItensNoChao
@onready var status_label: Label = get_node_or_null("Status")


func _ready() -> void:
	chef.health_changed.connect(func(current: int, maximum: int) -> void:
		print("[Chef] vida %d/%d (%.1f caveiras)" % [current, maximum, current / 2.0]))
	chef.died.connect(func() -> void: print("[Chef] MORREU"))
	for customer_name: StringName in [&"Patolino", &"Mandy", &"Johnny"]:
		var caster: CustomerAbilityCaster = get_caster(customer_name)
		if caster:
			caster.ability_cast.connect(func(index: int, ability: CustomerAbility) -> void:
				print("[%s] magia %d: %s" % [customer_name, index + 1, ability.name]))


## O nó "Habilidades" do cliente (ou null se ele não estiver na cena).
func get_caster(customer_name: StringName) -> CustomerAbilityCaster:
	return get_node_or_null(NodePath("%s/Habilidades" % customer_name)) as CustomerAbilityCaster


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if KEYS.has(key.keycode):
		var entry: Array = KEYS[key.keycode]
		cast(entry[0], entry[1])
	else:
		match key.keycode:
			KEY_0:
				_patience_level += 1
				print("[Paciência] todos perderam o nível %d" % _patience_level)
				for customer_name: StringName in [&"Patolino", &"Mandy", &"Johnny"]:
					var caster: CustomerAbilityCaster = get_caster(customer_name)
					if caster:
						caster.cast_for_patience_level(_patience_level)
			KEY_G:
				give_skewer()
			KEY_H:
				chef.heal_full()
				print("[Chef] curado")
			_:
				return
	get_viewport().set_input_as_handled()


## Lança a magia `index` do cliente `customer_name`.
func cast(customer_name: StringName, index: int) -> bool:
	var caster: CustomerAbilityCaster = get_caster(customer_name)
	if caster == null:
		return false
	if caster.cast(index):
		return true
	print("[%s] magia %d não saiu (ocupado, sem alvo ou limite de summons)" % [customer_name, index + 1])
	return false


func _process(_delta: float) -> void:
	if status_label == null:
		return
	var parts: PackedStringArray = []
	parts.append("velocidade %d%%" % roundi(SlowComponent.get_multiplier_of(chef) * 100.0))
	var stun: StunComponent = StunComponent.find_in(chef)
	if stun and stun.is_active():
		parts.append("ATORDOADO %.1f s" % stun.get_time_left())
	var confusion: ConfusionComponent = ConfusionComponent.find_in(chef)
	if confusion and confusion.is_active():
		parts.append("CONFUSO %.0f s" % confusion.get_time_left())
	if CaptureComponent.is_captured(chef):
		parts.append("PRESO (◀ ▶ para fugir)")
	if chef.is_dead():
		parts.append("MORTO (H revive)")
	status_label.text = "chef: " + " | ".join(parts)


## Coloca um espetinho na mão do chef (se estiver vazia).
func give_skewer() -> CarryableItem:
	if item_scene == null or give_item == null or chef.hand_component.has_item():
		return null
	var item := item_scene.instantiate() as CarryableItem
	item.data = give_item as ItemData
	items_container.add_child(item)
	chef.hand_component.hold(item)
	print("[Teste] espetinho na mão")
	return item
