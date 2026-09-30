extends Node
class_name SlowComponent
## LENTIDÃO: diminui a velocidade de andar de um personagem (símbolo da Mandy, caveira de
## fogo, demoninho grudado, poça de gosma, ...).
##
## Não precisa colocar na cena: quem aplica a lentidão cria o componente sozinho
## (injeção preguiçosa, igual ao QueueMovementComponent):
##
##     SlowComponent.apply(chef, self, 0.2)          # -20% até alguém tirar
##     SlowComponent.apply(chef, self, 0.5, 3.0)     # -50% por 3 segundos
##     SlowComponent.remove(chef, self)              # tira a lentidão desta fonte
##
## Cada FONTE (o símbolo, o demoninho, a caveira...) tem a sua lentidão. Aplicar de novo
## com a mesma fonte só ATUALIZA (não acumula). Com várias fontes ao mesmo tempo vale a
## MAIS FORTE (padrão) ou todas multiplicadas (`stacking`).
## Se a fonte for um nó e ele sumir, a lentidão dele sai sozinha.
##
## Mexe no `max_speed` do MovementComponent do personagem (ou no `max_speed` do próprio
## personagem, se ele não tiver MovementComponent). Dash não é afetado.


signal slow_changed(multiplier: float)


enum Stacking {
	STRONGEST,  ## vale só a lentidão mais forte
	MULTIPLY,   ## multiplica todas (20% + 50% = anda a 40%)
}


const NODE_NAME: StringName = &"SlowComponent"


@export var stacking: Stacking = Stacking.STRONGEST
## Pinta o personagem enquanto está lento (cor da fonte mais forte).
@export var tint_enabled: bool = true
## Menor velocidade possível, em fração da normal (nunca fica 100% parado).
@export_range(0.0, 1.0) var min_multiplier: float = 0.05


## Multiplicador atual (1 = normal, 0.1 = 10% da velocidade).
var multiplier: float = 1.0

## chave da fonte -> {percent, time_left (<0 = sem prazo), tint}
var _sources: Dictionary = {}
var _owner: Node = null
var _movement: Node = null
var _base_speed: float = -1.0
var _sprite: CanvasItem = null


# --- API estática (use estas) ------------------------------------------------------

## Deixa `target` `percent` mais lento (0.2 = 20% mais lento). `duration` <= 0 = até
## chamar `remove`. Retorna o componente (criado na hora, se preciso).
static func apply(target: Node, source: Variant, percent: float, duration: float = 0.0,
		tint: Color = Color(0.8, 0.6, 1.0)) -> SlowComponent:
	if target == null or not is_instance_valid(target):
		return null
	var component: SlowComponent = find_in(target)
	if component == null:
		component = SlowComponent.new()
		component.name = NODE_NAME
		target.add_child(component)
	component.add_slow(source, percent, duration, tint)
	return component


## Tira a lentidão que `source` colocou em `target`.
static func remove(target: Node, source: Variant) -> void:
	var component: SlowComponent = find_in(target)
	if component:
		component.remove_slow(source)


static func find_in(target: Node) -> SlowComponent:
	if target == null or not is_instance_valid(target):
		return null
	var node: Node = target.get_node_or_null(NodePath(NODE_NAME))
	if node is SlowComponent:
		return node
	for child in target.get_children():
		if child is SlowComponent:
			return child
	return null


## Multiplicador de velocidade de `target` agora (1 = sem lentidão).
static func get_multiplier_of(target: Node) -> float:
	var component: SlowComponent = find_in(target)
	return component.multiplier if component else 1.0


# --- Instância -------------------------------------------------------------------------

func _ready() -> void:
	_owner = get_parent()
	_movement = _find_movement(_owner)
	_sprite = _owner.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if _base_speed < 0.0:
		_base_speed = _read_speed()
	if not _sources.is_empty():
		_refresh()


func add_slow(source: Variant, percent: float, duration: float = 0.0,
		tint: Color = Color(0.8, 0.6, 1.0)) -> void:
	_sources[_key(source)] = {
		&"percent": clampf(percent, 0.0, 1.0),
		&"time_left": duration if duration > 0.0 else -1.0,
		&"tint": tint,
		&"ref": weakref(source) if source is Object else null,
	}
	_refresh()


func remove_slow(source: Variant) -> void:
	if _sources.erase(_key(source)):
		_refresh()


func has_slow(source: Variant) -> bool:
	return _sources.has(_key(source))


func clear() -> void:
	_sources.clear()
	_refresh()


func _physics_process(delta: float) -> void:
	if _sources.is_empty():
		return
	var changed: bool = false
	for key in _sources.keys():
		var entry: Dictionary = _sources[key]
		var ref: WeakRef = entry[&"ref"]
		if ref != null and ref.get_ref() == null:
			_sources.erase(key)  # a fonte sumiu (ex.: demoninho morreu)
			changed = true
			continue
		if entry[&"time_left"] > 0.0:
			entry[&"time_left"] -= delta
			if entry[&"time_left"] <= 0.0:
				_sources.erase(key)
				changed = true
	if changed:
		_refresh()


# --- Interno -----------------------------------------------------------------------

func _key(source: Variant) -> Variant:
	if source is Object:
		return (source as Object).get_instance_id()
	return source


func _refresh() -> void:
	if _owner == null:
		return
	var value: float = 1.0
	var strongest: float = 0.0
	var tint: Color = Color.WHITE
	for entry: Dictionary in _sources.values():
		var percent: float = entry[&"percent"]
		if stacking == Stacking.MULTIPLY:
			value *= 1.0 - percent
		if percent >= strongest:
			strongest = percent
			tint = entry[&"tint"]
	if stacking == Stacking.STRONGEST:
		value = 1.0 - strongest
	if not _sources.is_empty():
		value = maxf(value, min_multiplier)

	if is_equal_approx(value, multiplier) and not _sources.is_empty():
		return
	multiplier = value
	_write_speed(_base_speed * multiplier)
	if tint_enabled and _sprite:
		_sprite.self_modulate = Color.WHITE if _sources.is_empty() else tint
	slow_changed.emit(multiplier)


func _find_movement(node: Node) -> Node:
	if node == null:
		return null
	var by_name: Node = node.get_node_or_null("MovementComponent")
	if by_name:
		return by_name
	for child in node.get_children():
		if child is MovementComponent:
			return child
	return null


func _read_speed() -> float:
	if _movement and &"max_speed" in _movement:
		return float(_movement.max_speed)
	if _owner and &"max_speed" in _owner:
		return float(_owner.max_speed)
	return 0.0


func _write_speed(speed: float) -> void:
	# max_speed é int no MovementComponent/Character: arredonda e nunca zera.
	var value: int = maxi(roundi(speed), 1) if _base_speed > 0.0 else 0
	if _movement and &"max_speed" in _movement:
		_movement.max_speed = value
	elif _owner and &"max_speed" in _owner:
		_owner.max_speed = value
