extends HBoxContainer
class_name ManaBar
## Barra de MANA em potinhos, logo abaixo das caveiras de vida.
## Cada potinho = 1 barra de habilidade.
##
## Duas folhas de arte (quadros de 24x24 lado a lado; a quantidade de quadros é lida da largura):
##   idle_sheet  (jscoutinho_ui_mana_idle.png, 11 quadros) -> potinho cheio, brilho em loop
##   fade_sheet  (jscoutinho_ui_mana_fade_out.png, 8 quadros) -> potinho esvaziando
##
## Gastou  -> toca o fade_out e o potinho fica "apagado" (empty_modulate).
## Recuperou -> toca o fade_out AO CONTRÁRIO (enchendo) e volta ao brilho.
##
## Não sabe quem é o dono da mana: quem usa chama `set_mana(atual, máximo)`.
## Reutilizável: qualquer recurso em "potinhos" (fôlego, munição, cargas...).


enum SlotState { FULL, DRAINING, EMPTY, FILLING }


@export_group("Arte")
@export var idle_sheet: Texture2D
@export var fade_sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(24, 24)
## Tamanho de cada potinho na tela (1 = tamanho da arte).
@export var slot_scale: float = 1.0

@export_group("Animação")
## Quadros por segundo do brilho (idle).
@export var idle_fps: float = 8.0
## Pausa (s) entre um brilho e outro. 0 = brilha sem parar.
@export var idle_pause: float = 1.2
## Atraso do brilho de um potinho para o próximo (efeito "onda").
@export var idle_wave_delay: float = 0.12
## Quadros por segundo do esvaziar/encher.
@export var fade_fps: float = 16.0
## Como fica o potinho vazio (usa o 1º quadro do idle com esta cor).
@export var empty_modulate: Color = Color(0.3, 0.3, 0.42, 0.45)
## "Soco" no potinho que mudou. 1 = desliga.
@export var punch_scale: float = 1.3
@export var punch_time: float = 0.18

@export_group("Sem mana")
## Tremida quando tenta usar habilidade sem mana.
@export var shake_strength: float = 3.0
@export var shake_time: float = 0.3
@export var shake_color: Color = Color(1.0, 0.45, 0.45)


var _idle_frames: Array[AtlasTexture] = []
var _fade_frames: Array[AtlasTexture] = []
var _slots: Array[TextureRect] = []
var _states: Array[int] = []
var _anim_time: Array[float] = []
var _clock: float = 0.0
var _shake_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frames()


func set_mana(current: int, maximum: int) -> void:
	if _idle_frames.is_empty():
		_build_frames()
	maximum = maxi(maximum, 0)
	current = clampi(current, 0, maximum)
	var first_time: bool = _slots.is_empty()
	_resize(maximum)

	for i in _slots.size():
		var should_be_full: bool = i < current
		var state: int = _states[i]
		var is_full_side: bool = state == SlotState.FULL or state == SlotState.FILLING
		if should_be_full == is_full_side:
			continue
		if first_time or not is_inside_tree():
			_states[i] = SlotState.FULL if should_be_full else SlotState.EMPTY
		else:
			_states[i] = SlotState.FILLING if should_be_full else SlotState.DRAINING
			_anim_time[i] = 0.0
			_punch(_slots[i])
		_apply_visual(i)


## Tremida + piscada vermelha (sem mana suficiente).
func shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	var origin_x: float = position.x
	modulate = shake_color
	_shake_tween = create_tween()
	var steps: int = 6
	for i in steps:
		var offset: float = shake_strength * (1.0 if i % 2 == 0 else -1.0) * (1.0 - float(i) / steps)
		_shake_tween.tween_property(self, "position:x", origin_x + offset, shake_time / steps)
	_shake_tween.tween_property(self, "position:x", origin_x, 0.02)
	_shake_tween.parallel().tween_property(self, "modulate", Color.WHITE, shake_time * 0.5)


func _process(delta: float) -> void:
	_clock += delta
	for i in _slots.size():
		match _states[i]:
			SlotState.DRAINING, SlotState.FILLING:
				_anim_time[i] += delta
				if _anim_time[i] * fade_fps >= _fade_frames.size():
					_states[i] = SlotState.EMPTY if _states[i] == SlotState.DRAINING else SlotState.FULL
		_apply_visual(i)


func _apply_visual(i: int) -> void:
	var slot: TextureRect = _slots[i]
	match _states[i]:
		SlotState.FULL:
			slot.texture = _frame_at(_idle_frames, _idle_frame_index(i))
			slot.self_modulate = Color.WHITE
		SlotState.EMPTY:
			slot.texture = _frame_at(_idle_frames, 0)
			slot.self_modulate = empty_modulate
		SlotState.DRAINING:
			slot.texture = _frame_at(_fade_frames, int(_anim_time[i] * fade_fps))
			slot.self_modulate = Color.WHITE
		SlotState.FILLING:
			var last: int = _fade_frames.size() - 1
			slot.texture = _frame_at(_fade_frames, last - int(_anim_time[i] * fade_fps))
			slot.self_modulate = Color.WHITE


## Brilho em loop com pausa, e cada potinho um pouco atrasado (onda).
func _idle_frame_index(i: int) -> int:
	if _idle_frames.size() <= 1 or idle_fps <= 0.0:
		return 0
	var anim_len: float = _idle_frames.size() / idle_fps
	var cycle: float = anim_len + maxf(idle_pause, 0.0)
	var t: float = fposmod(_clock - i * idle_wave_delay, cycle)
	if t >= anim_len:
		return 0
	return int(t * idle_fps)


func _build_frames() -> void:
	_idle_frames = _slice(idle_sheet)
	_fade_frames = _slice(fade_sheet)


func _slice(sheet: Texture2D) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	if sheet == null:
		return frames
	var columns: int = maxi(1, int(sheet.get_width() / frame_size.x))
	for i in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.append(atlas)
	return frames


func _frame_at(frames: Array[AtlasTexture], index: int) -> Texture2D:
	if frames.is_empty():
		return null
	return frames[clampi(index, 0, frames.size() - 1)]


func _resize(count: int) -> void:
	while _slots.size() < count:
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(frame_size) * slot_scale
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.pivot_offset = slot.custom_minimum_size * 0.5
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(slot)
		_slots.append(slot)
		_states.append(SlotState.EMPTY)
		_anim_time.append(0.0)
	while _slots.size() > count:
		_slots.pop_back().queue_free()
		_states.pop_back()
		_anim_time.pop_back()


func _punch(slot: TextureRect) -> void:
	if punch_scale == 1.0 or punch_time <= 0.0:
		return
	slot.scale = Vector2.ONE * punch_scale
	create_tween().tween_property(slot, "scale", Vector2.ONE, punch_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
