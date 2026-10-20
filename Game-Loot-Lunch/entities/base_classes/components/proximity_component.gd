extends Area2D
class_name ProximityComponent
## Sensor de PRESENÇA: avisa quando alguém entra ou sai de um raio em volta do dono.
## Não decide o que fazer — quem usa conecta nos sinais ou pergunta `has_target()`.
##
## Reutilizável: balão de pedido do cliente, dica de tecla em cima de uma estação,
## NPC que vira a cabeça quando o jogador chega perto, etc.
##
## Camada sugerida: collision_layer = 0, collision_mask = 2 (Player).
## O raio é o CollisionShape2D filho (CircleShape2D).


signal target_entered(body: Node2D)
signal target_exited(body: Node2D)
## Emitido só quando muda de "ninguém perto" para "alguém perto" (e vice-versa).
## Com 2 jogadores, o segundo chegando não emite de novo.
signal presence_changed(is_present: bool)


## Se preenchido, só conta corpos que estão neste grupo. Vazio = qualquer corpo da máscara.
@export var required_group: StringName = &""
## Ignora o corpo que é dono deste componente (caso a máscara pegue a camada dele).
@export var ignore_own_body: bool = true


var _targets: Array = []


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func has_target() -> bool:
	_prune()
	return not _targets.is_empty()


func get_targets() -> Array:
	_prune()
	return _targets.duplicate()


func _on_body_entered(body: Node2D) -> void:
	if not _accepts(body) or _targets.has(body):
		return
	var was_present: bool = has_target()
	_targets.append(body)
	target_entered.emit(body)
	if not was_present:
		presence_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if not _targets.has(body):
		return
	_targets.erase(body)
	target_exited.emit(body)
	if not has_target():
		presence_changed.emit(false)


func _accepts(body: Node2D) -> bool:
	if body == null:
		return false
	if ignore_own_body and body.is_ancestor_of(self):
		return false
	if required_group != &"" and not body.is_in_group(required_group):
		return false
	return true


## Remove quem foi destruído sem sair da área.
func _prune() -> void:
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
