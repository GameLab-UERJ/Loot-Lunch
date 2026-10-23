extends RandomEvent
class_name FlameRandomEvent
## LABAREDA aleatória da churrasqueira: de tempos em tempos (com chance), mostra um
## alerta e solta uma chama que TORRA todos os espetinhos que estiverem no fogo.
##
## Regras (correções de 23/10/2026):
##   - só UMA chama por vez (antes cada espetinho colocado criava uma chama nova);
##   - colocar espetinho NÃO dispara mais a chama garantida (`trigger_on_item_placed`
##     desligado por padrão; se ligar, ainda respeita a chance e o intervalo mínimo);
##   - respeita um intervalo mínimo entre chamas (`min_time_between_events`);
##   - tudo para quando o jogo pausa (tutorial, menu de pausa, tela de fim).


@export var flame_scene: PackedScene
@export var event_source_path: NodePath
## Segundos de alerta antes da chama (tempo para o jogador tirar os espetinhos).
@export var warning_duration: float = 1.5
@export var require_source_activity: bool = true
## Colocar um espetinho também "sorteia" uma chama (com a mesma chance do timer).
@export var trigger_on_item_placed: bool = false
## Intervalo mínimo entre o fim de uma chama e o começo da próxima (segundos).
@export var min_time_between_events: float = 6.0

var _active_flame: FlameTrap = null
var _cooldown_left: float = 0.0


func _ready() -> void:
	super()
	var source: Node = get_node_or_null(event_source_path)
	if source and source.has_signal("item_placed"):
		source.connect("item_placed", _on_item_placed)


func _process(delta: float) -> void:
	# Node2D com process_mode herdado: não conta enquanto o jogo está pausado.
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _can_trigger_event() -> bool:
	# Uma chama de cada vez e respeitando o intervalo mínimo.
	if is_instance_valid(_active_flame) or _cooldown_left > 0.0:
		return false
	if not require_source_activity:
		return true
	if event_source_path.is_empty():
		return true
	var source: Node = get_node_or_null(event_source_path)
	if source == null or not source.has_method("get_count"):
		return false
	return int(source.call("get_count")) > 0


func _activate_event() -> void:
	if not flame_scene:
		return
	var flame: FlameTrap = flame_scene.instantiate() as FlameTrap
	if flame == null:
		push_warning("FlameRandomEvent '%s': flame_scene não é um FlameTrap." % name)
		return
	flame.warning_duration = warning_duration
	add_child(flame)
	_active_flame = flame
	var source: Node = get_node_or_null(event_source_path)
	if source and source.has_method("burn_items"):
		flame.activated.connect(Callable(source, "burn_items"))
	flame.deactivated.connect(_on_flame_deactivated.bind(flame))
	flame.trigger()


func _on_flame_deactivated(flame: FlameTrap) -> void:
	if flame == _active_flame:
		_active_flame = null
	_cooldown_left = min_time_between_events
	if is_instance_valid(flame):
		flame.queue_free()


func _on_item_placed(_slot: CookingSlot, _item: CarryableItem) -> void:
	if trigger_on_item_placed:
		trigger_random_event()
