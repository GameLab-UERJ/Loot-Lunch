extends Node2D
class_name StatusEffectComponent
## BASE de STATUS COM TEMPO (atordoado, confuso, ...). Cada status é um filho deste:
##   StunComponent       (atordoado: não anda nem age)
##   ConfusionComponent  (confuso: setas invertidas)
##
## Igual ao SlowComponent, não precisa colocar na cena: quem aplica o status cria o
## componente sozinho (injeção preguiçosa):
##
##     StunComponent.apply(chef, fonte, 2.0, arte)      # atordoado por 2 s
##     ConfusionComponent.apply(chef, fonte, 120.0, arte)
##     StunComponent.is_active_on(chef)                 # está atordoado?
##
## Regras comuns:
##   - cada FONTE (raio, esfera, nuvem...) tem o seu tempo. Aplicar de novo com a mesma
##     fonte RENOVA (fica com o maior tempo), não empilha;
##   - o status vale enquanto qualquer fonte tiver tempo;
##   - `visual` (SheetAnimation) aparece em cima do personagem enquanto dura. Duas fontes
##     com a mesma arte mostram UM desenho só;
##   - personagem morreu -> o status acaba (não volta junto quando ele revive).
##
## Quem herda sobrescreve `_on_started()`, `_on_ended()` e `_on_active_physics(delta)`.


signal started
signal ended


## chave da fonte -> {time_left, visual}
var _sources: Dictionary = {}
## SheetAnimation -> AnimatedSprite2D
var _sprites: Dictionary = {}
var _active: bool = false


# --- API estática (as classes filhas repassam para cá) ------------------------

static func _apply_status(kind: GDScript, node_name: StringName, target: Node, source: Variant,
		duration: float, visual: SheetAnimation) -> StatusEffectComponent:
	if target == null or not is_instance_valid(target) or duration <= 0.0:
		return null
	if target.has_method(&"is_dead") and target.is_dead():
		return null
	var component: StatusEffectComponent = _find_status(kind, node_name, target)
	if component == null:
		component = kind.new()
		component.name = node_name
		target.add_child(component)
	component.add_source(source, duration, visual)
	return component


static func _find_status(kind: GDScript, node_name: StringName, target: Node) -> StatusEffectComponent:
	if target == null or not is_instance_valid(target):
		return null
	var node: Node = target.get_node_or_null(NodePath(node_name))
	if node != null and node.get_script() == kind:
		return node
	for child in target.get_children():
		if child.get_script() == kind:
			return child
	return null


# --- Instância -------------------------------------------------------------------

func add_source(source: Variant, duration: float, visual: SheetAnimation = null) -> void:
	var key: Variant = _key(source)
	var time_left: float = duration
	if _sources.has(key):
		time_left = maxf(time_left, _sources[key][&"time_left"])
	_sources[key] = {&"time_left": time_left, &"visual": visual}
	_refresh()


func remove_source(source: Variant) -> void:
	if _sources.erase(_key(source)):
		_refresh()


func clear() -> void:
	_sources.clear()
	_refresh()


func is_active() -> bool:
	return _active


## Segundos até o status acabar (a fonte mais longa).
func get_time_left() -> float:
	var longest: float = 0.0
	for entry: Dictionary in _sources.values():
		longest = maxf(longest, entry[&"time_left"])
	return longest


func get_target() -> Node:
	return get_parent()


func _ready() -> void:
	# Morreu -> acaba na hora (sem esperar o próximo quadro).
	var target: Node = get_parent()
	if target != null and target.has_signal(&"died") and not target.died.is_connected(clear):
		target.died.connect(clear)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var target: Node = get_parent()
	if target != null and target.has_method(&"is_dead") and target.is_dead():
		clear()
		return

	var changed: bool = false
	for key in _sources.keys():
		_sources[key][&"time_left"] -= delta
		if _sources[key][&"time_left"] <= 0.0:
			_sources.erase(key)
			changed = true
	if changed:
		_refresh()
	if _active:
		_on_active_physics(delta)


func _exit_tree() -> void:
	if _active:
		_active = false
		_on_ended()


# --- Para sobrescrever ---------------------------------------------------------

func _on_started() -> void:
	pass


func _on_ended() -> void:
	pass


func _on_active_physics(_delta: float) -> void:
	pass


# --- Interno -------------------------------------------------------------------

func _key(source: Variant) -> Variant:
	if source is Object:
		return (source as Object).get_instance_id()
	return source


func _refresh() -> void:
	_update_sprites()
	var now_active: bool = not _sources.is_empty()
	if now_active == _active:
		return
	_active = now_active
	if _active:
		_on_started()
		started.emit()
	else:
		_on_ended()
		ended.emit()


## Um desenho por arte usada pelas fontes ativas.
func _update_sprites() -> void:
	var wanted: Array = []
	for entry: Dictionary in _sources.values():
		var visual: SheetAnimation = entry[&"visual"]
		if visual != null and not wanted.has(visual):
			wanted.append(visual)

	for visual: SheetAnimation in _sprites.keys():
		if not wanted.has(visual):
			var old: Node = _sprites[visual]
			if is_instance_valid(old):
				old.queue_free()
			_sprites.erase(visual)

	for visual: SheetAnimation in wanted:
		if not _sprites.has(visual):
			var sprite: AnimatedSprite2D = visual.create_sprite()
			add_child(sprite)
			_sprites[visual] = sprite
