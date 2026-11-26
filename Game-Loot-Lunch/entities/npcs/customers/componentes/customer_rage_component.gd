extends Node
class_name CustomerRageComponent
## RAIVA PURA: o cliente que perdeu toda a paciência NÃO vai embora. Ele fica no lugar,
## pulsando vermelho, e lança as magias de `levels` sem parar até ser atendido.
##
## Não sabe o que cada magia faz: só chama `CustomerAbilityCaster.cast_for_patience_level`
## (o mesmo gancho da paciência). A cada `cast_interval` ele sorteia uma das magias da
## lista que esteja pronta e lança. Se nenhuma estiver pronta, tenta de novo no próximo frame.
##
## Uso: quem decide QUANDO a raiva começa é outro sistema (ex.: CustomerWaveDirector, quando
## a paciência chega a 0). Ele só chama `start()` e, quando o cliente for atendido, `stop()`.
##
##   Cliente
##   ├── Habilidades (CustomerAbilityCaster)
##   └── Raiva (CustomerRageComponent)   <- criado por código ou colocado na cena


signal rage_started
signal rage_stopped
## Uma magia saiu durante a raiva.
signal rage_cast(level: int)


## Níveis de magia que a raiva usa (1 = magia 1, 2 = magia 2...). A ultimate fica de fora
## se o número dela não estiver aqui.
@export var levels: Array[int] = [1, 2]
## Segundos entre uma magia e outra. Quanto menor, mais desenfreado.
@export var cast_interval: float = 1.0
## Variação aleatória do intervalo (0.3 = de 70% a 130% do `cast_interval`).
@export_range(0.0, 1.0) var interval_jitter: float = 0.3
## true = espera a magia anterior terminar antes de lançar outra (sem sobrepor).
@export var wait_for_previous: bool = false
## Cliente com raiva. Vazio = o pai deste nó.
@export var customer: Node2D
## Nó com as magias. Vazio = filho "Habilidades" do cliente.
@export var caster: CustomerAbilityCaster

@export_group("Visual")
## Nó que pisca vermelho (relativo ao cliente).
@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@export var rage_color: Color = Color(1.0, 0.42, 0.38)
## Duração de meia piscada (claro -> vermelho).
@export var pulse_time: float = 0.25

@export_group("Debug")
@export var debug_print: bool = false


var _active: bool = false
var _time_to_next: float = 0.0
var _pulse: Tween = null
var _sprite: CanvasItem = null


func _ready() -> void:
	if customer == null:
		customer = get_parent() as Node2D
	if caster == null and customer:
		caster = customer.get_node_or_null("Habilidades") as CustomerAbilityCaster
	if caster == null:
		push_warning("CustomerRageComponent (%s): nenhum CustomerAbilityCaster ('Habilidades')." % _customer_name())


func _process(delta: float) -> void:
	if not _active or caster == null:
		return
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	if wait_for_previous and caster.is_casting():
		return
	if _cast_random():
		_time_to_next = _roll_interval()


## Entra na raiva (a primeira magia sai já no próximo frame).
func start() -> void:
	if _active:
		return
	_active = true
	_time_to_next = 0.0
	_start_pulse()
	rage_started.emit()
	if debug_print:
		print("[Raiva] %s entrou em RAIVA PURA" % _customer_name())


## Sai da raiva (ex.: o cliente foi atendido e vai embora).
func stop() -> void:
	if not _active:
		return
	_active = false
	_stop_pulse()
	rage_stopped.emit()


func is_active() -> bool:
	return _active


# --- Interno -------------------------------------------------------------------

## Sorteia uma das magias da lista que esteja pronta e lança.
func _cast_random() -> bool:
	var order: Array[int] = levels.duplicate()
	order.shuffle()
	for level in order:
		if caster.cast_for_patience_level(level):
			rage_cast.emit(level)
			if debug_print:
				print("[Raiva] %s -> magia %d" % [_customer_name(), level])
			return true
	return false


func _roll_interval() -> float:
	var jitter: float = randf_range(-interval_jitter, interval_jitter)
	return maxf(cast_interval * (1.0 + jitter), 0.05)


func _start_pulse() -> void:
	_sprite = customer.get_node_or_null(sprite_path) as CanvasItem if customer else null
	if _sprite == null:
		return
	_stop_pulse()
	_pulse = _sprite.create_tween().set_loops()
	_pulse.tween_property(_sprite, "modulate", rage_color, pulse_time) \
		.set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_sprite, "modulate", rage_color.lerp(Color.WHITE, 0.55), pulse_time) \
		.set_trans(Tween.TRANS_SINE)


func _stop_pulse() -> void:
	if _pulse:
		_pulse.kill()
		_pulse = null
	if is_instance_valid(_sprite):
		_sprite.modulate = Color.WHITE


func _customer_name() -> String:
	return String(customer.name) if customer else String(name)
