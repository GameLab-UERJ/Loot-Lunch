extends Node2D
class_name CaptureComponent
## "BARRIGA": prende um personagem (ex.: o chef engolido pelo pato) e deixa ele tentar se
## soltar apertando teclas ALTERNADAS (padrão: ◀ e ▶, as ações ui_left / ui_right).
##
## Reutilizável por qualquer coisa que "agarra" o jogador: pato que engole, demônio que
## gruda, planta carnívora, armadilha... O dono decide QUANDO capturar e o que acontece
## no final; este componente cuida do resto:
##
##   capture(alvo)   -> trava o controle, tira a colisão, deixa invulnerável, larga o item
##                      da mão e mantém o alvo grudado aqui. (`hide_target` esconde)
##   escape_active   -> liga o "aperte ◀ ▶": barra de progresso + setinhas em cima
##   escaped         -> encheu a barra: o alvo é solto, com alguns segundos de invencibilidade
##   transfer_to(x)  -> passa o prisioneiro para outra barriga (pato que come o pato cheio)
##   finalize()      -> solta e mata o alvo, não importa a vida que tinha
##
## A barra usa o ProgressBarComponent. Se não houver um filho ProgressBarComponent, ela é
## criada por código em `ui_offset`.
##
## Qualquer script pode perguntar se alguém está preso: `CaptureComponent.is_captured(no)`.


signal captured(target: Node2D)
signal escaped(target: Node2D)
signal finalized(target: Node2D)
## Soltou o alvo (fuga, transferência ou fim). Depois deste sinal a barriga está vazia.
signal released(target: Node2D)
signal escape_progress_changed(value: float)


const META_CAPTOR: StringName = &"captured_by"


@export_group("Fuga")
## Deixa o prisioneiro tentar se soltar. Desligado = só sai por `release`/`finalize`.
@export var escape_enabled: bool = true
## Ações do Input Map usadas para se soltar.
@export var escape_actions: Array[StringName] = [&"ui_left", &"ui_right"]
## Precisa ALTERNAR as teclas (◀ ▶ ◀ ▶). Apertar a mesma duas vezes não conta.
@export var must_alternate: bool = true
## Quanto cada aperto certo enche (0..1). 0.07 = ~15 apertos.
@export_range(0.01, 1.0) var progress_per_press: float = 0.07
## Quanto a barra esvazia por segundo se o jogador parar de apertar.
@export_range(0.0, 2.0) var decay_per_second: float = 0.15
## Segundos de invencibilidade depois de escapar (0 = usa o do Character).
@export var escape_invincibility: float = 1.2
## Para onde o alvo é "cuspido" ao escapar, relativo à barriga.
@export var escape_push: Vector2 = Vector2(0, 16)

@export_group("Visual")
## Posição da barra e das setinhas, relativa a este nó.
@export var ui_offset: Vector2 = Vector2(0, -22)
@export var bar_size: Vector2 = Vector2(26, 4)
@export var bar_color: Color = Color(1.0, 0.85, 0.2)
@export var arrow_color: Color = Color(1.0, 1.0, 1.0)


var target: Node2D = null
## Liga/desliga o "aperte ◀ ▶" (o dono liga quando termina a animação de engolir).
var escape_active: bool = false:
	set(value):
		escape_active = value and escape_enabled
		_update_ui()
var escape_progress: float = 0.0

var _saved: Dictionary = {}
var _last_action: StringName = &""
var _bar: ProgressBarComponent = null
var _blink: float = 0.0


## Alguém está preso em alguma barriga?
static func is_captured(node: Node) -> bool:
	return get_captor(node) != null


static func get_captor(node: Node) -> CaptureComponent:
	if node == null or not is_instance_valid(node) or not node.has_meta(META_CAPTOR):
		return null
	var captor: Variant = node.get_meta(META_CAPTOR)
	if captor is CaptureComponent and is_instance_valid(captor):
		return captor
	return null


## Alvo "disponível" para clientes e summons: existe, não está preso e não está morto.
static func is_available_target(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	if is_captured(node):
		return false
	if node.has_method(&"is_dead") and node.is_dead():
		return false
	return true


func _ready() -> void:
	for child in get_children():
		if child is ProgressBarComponent:
			_bar = child
			break
	if _bar == null:
		_bar = ProgressBarComponent.new()
		_bar.name = "BarraFuga"
		_bar.size = bar_size
		_bar.fill_color = bar_color
		_bar.position = ui_offset
		_bar.z_index = 30
		add_child(_bar)
	_update_ui()


func has_target() -> bool:
	return is_instance_valid(target)


## Prende o alvo. `hide_now` = some na hora (false = o dono esconde depois com `hide_target`).
func capture(new_target: Node2D, hide_now: bool = true) -> bool:
	if has_target() or not is_available_target(new_target):
		return false

	HandComponent.force_drop(new_target)
	_take(new_target, {})
	if hide_now:
		hide_target()
	captured.emit(target)
	return true


func hide_target() -> void:
	if has_target():
		target.visible = false


## O prisioneiro vai para outra barriga (sem ser solto no meio do caminho).
func transfer_to(other: CaptureComponent) -> bool:
	if not has_target() or other == null or other == self or other.has_target():
		return false
	var moving: Node2D = target
	var saved: Dictionary = _saved
	_clear()
	released.emit(moving)
	other._take(moving, saved)
	other.captured.emit(moving)
	return true


## Solta sem efeito nenhum (ex.: o dono sumiu).
func release() -> Node2D:
	if not has_target():
		return null
	var freed: Node2D = target
	_restore(freed)
	_clear()
	released.emit(freed)
	return freed


## Encheu a barra: solta com invencibilidade e empurrãozinho.
func escape() -> void:
	var freed: Node2D = release()
	if freed == null:
		return
	freed.global_position = global_position + escape_push
	_grant_invincibility(freed)
	escaped.emit(freed)


## Solta e MATA o alvo, não importa quanta vida ele tinha.
func finalize() -> void:
	var victim: Node2D = release()
	if victim == null:
		return
	if victim.has_method(&"kill"):
		victim.kill()
	elif victim.has_method(&"take_damage"):
		if &"is_invincible" in victim:
			victim.is_invincible = false
		if &"is_invulnerable" in victim:
			victim.is_invulnerable = false
		var hp_left: int = int(victim.get(&"hp")) if &"hp" in victim else 999
		victim.take_damage(maxi(hp_left, 1), Vector2.ZERO, 0)
	finalized.emit(victim)


## Um aperto de tecla de fuga. Público para testes / controle na tela.
func register_escape_press(action: StringName) -> void:
	if not escape_active or not has_target():
		return
	if must_alternate and action == _last_action:
		return
	_last_action = action
	escape_progress = minf(escape_progress + progress_per_press, 1.0)
	escape_progress_changed.emit(escape_progress)
	_update_ui()
	if escape_progress >= 1.0:
		escape()


func _unhandled_input(event: InputEvent) -> void:
	if not escape_active or not has_target() or event.is_echo():
		return
	for action in escape_actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			register_escape_press(action)
			get_viewport().set_input_as_handled()
			return


func _physics_process(delta: float) -> void:
	if not has_target():
		return
	target.global_position = global_position
	if target is CharacterBody2D:
		target.velocity = Vector2.ZERO

	if escape_active and escape_progress > 0.0 and decay_per_second > 0.0:
		escape_progress = maxf(escape_progress - decay_per_second * delta, 0.0)
		escape_progress_changed.emit(escape_progress)
		_update_ui()


func _process(delta: float) -> void:
	if escape_active:
		_blink += delta
		queue_redraw()


func _exit_tree() -> void:
	# O dono sumiu com alguém dentro: devolve o alvo inteiro.
	if has_target():
		release()


# --- Setinhas ◀ ▶ -------------------------------------------------------------

func _draw() -> void:
	if not escape_active or escape_actions.size() < 2:
		return
	var expected: int = 0
	if must_alternate and _last_action == escape_actions[0]:
		expected = 1
	var pulse: float = 0.8 + 0.2 * sin(_blink * 14.0)
	var y: float = ui_offset.y - 7.0
	var gap: float = bar_size.x * 0.5 + 4.0
	_draw_arrow(Vector2(ui_offset.x - gap, y), -1.0, expected == 0, pulse)
	_draw_arrow(Vector2(ui_offset.x + gap, y), 1.0, expected == 1, pulse)


func _draw_arrow(center: Vector2, side: float, highlighted: bool, pulse: float) -> void:
	var color: Color = arrow_color
	color.a = pulse if highlighted else 0.35
	var size: float = (4.0 + pulse) if highlighted else 3.0
	var points := PackedVector2Array([
		center + Vector2(side * size, 0),
		center + Vector2(-side * size * 0.6, -size),
		center + Vector2(-side * size * 0.6, size),
	])
	draw_colored_polygon(points, Color(0, 0, 0, color.a * 0.7))
	var inner := PackedVector2Array()
	for p in points:
		inner.append(center + (p - center) * 0.7)
	draw_colored_polygon(inner, color)


# --- Interno -------------------------------------------------------------------

func _take(new_target: Node2D, saved: Dictionary) -> void:
	target = new_target
	escape_progress = 0.0
	_last_action = &""
	_saved = saved if not saved.is_empty() else _snapshot(new_target)
	target.set_meta(META_CAPTOR, self)

	if new_target.has_method(&"interrupt_abilities"):
		new_target.interrupt_abilities()
	if &"can_control" in new_target:
		new_target.can_control = false
	if &"is_invulnerable" in new_target:
		new_target.is_invulnerable = true
	if new_target is CollisionObject2D:
		new_target.collision_layer = 0
		new_target.collision_mask = 0
	if new_target is CharacterBody2D:
		new_target.velocity = Vector2.ZERO
	new_target.global_position = global_position
	_update_ui()


func _snapshot(node: Node2D) -> Dictionary:
	var saved := {&"visible": node.visible}
	if &"can_control" in node:
		saved[&"can_control"] = node.can_control
	if &"is_invulnerable" in node:
		saved[&"is_invulnerable"] = node.is_invulnerable
	if node is CollisionObject2D:
		saved[&"collision_layer"] = node.collision_layer
		saved[&"collision_mask"] = node.collision_mask
	return saved


func _restore(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	for key in _saved:
		node.set(key, _saved[key])
	if node.has_meta(META_CAPTOR):
		node.remove_meta(META_CAPTOR)


func _clear() -> void:
	target = null
	_saved = {}
	escape_active = false
	escape_progress = 0.0
	_last_action = &""
	_update_ui()


func _grant_invincibility(node: Node2D) -> void:
	if not &"is_invincible" in node:
		return
	node.is_invincible = true
	var time: float = escape_invincibility
	if time <= 0.0:
		time = float(node.get(&"invencibility_time")) if &"invencibility_time" in node else 1.0
	var weak: WeakRef = weakref(node)
	node.get_tree().create_timer(time, false).timeout.connect(func() -> void:
		var still: Object = weak.get_ref()
		if still:
			still.is_invincible = false)


func _update_ui() -> void:
	if _bar:
		_bar.set_progress(escape_progress)
		_bar.set_bar_visible(escape_active and has_target())
	queue_redraw()
