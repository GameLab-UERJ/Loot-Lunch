extends Node
class_name CookingStationFSM
## Máquina de estados VISUAL da churrasqueira (serve para qualquer CookingStation).
## Não muda regra nenhuma do cozimento: só olha as bocas e escolhe a animação.
##
## Estados:
##   VAZIA    -> nenhuma boca ocupada. Fogo baixinho.            (loop)
##   ASSANDO  -> tem espetinho no fogo.                          (loop)
##   ALERTA   -> algum espetinho já está TORRADO: vai queimar!   (loop)
##   RISADA   -> um espetinho queimou e sumiu. Ri do jogador,
##               toca UMA vez e volta para o estado que couber.  (uma vez)
##
## Cada estado tem sua spritesheet (uma linha, quadros lado a lado). O número de
## quadros sai da largura da imagem dividida por `frame_size.x`.
##
## Uso: filho da estação, com `sprite` apontando para o AnimatedSprite2D dela.


enum GrillState { IDLE, COOKING, WARNING, LAUGH }


signal state_changed(previous_state: GrillState, new_state: GrillState)


const ANIMATIONS: Dictionary = {
	GrillState.IDLE: &"vazia",
	GrillState.COOKING: &"assando",
	GrillState.WARNING: &"alerta",
	GrillState.LAUGH: &"risada",
}


## Estação observada. Se vazio, usa o nó pai.
@export var station: CookingStation
## Sprite animado da estação (é nele que as animações são montadas).
@export var sprite: AnimatedSprite2D
## Tamanho de cada quadro das spritesheets.
@export var frame_size: Vector2i = Vector2i(80, 96)

@export_group("Vazia")
@export var idle_sheet: Texture2D
@export var idle_fps: float = 8.0

@export_group("Assando")
@export var cooking_sheet: Texture2D
@export var cooking_fps: float = 10.0

@export_group("Alerta (torrando)")
@export var warning_sheet: Texture2D
@export var warning_fps: float = 12.0

@export_group("Risada (perdeu o espetinho)")
@export var laugh_sheet: Texture2D
@export var laugh_fps: float = 12.0


var state: GrillState = GrillState.IDLE
var previous_state: GrillState = GrillState.IDLE


func _ready() -> void:
	if station == null:
		station = get_parent() as CookingStation
	if sprite == null:
		push_warning("CookingStationFSM '%s': nenhum AnimatedSprite2D em `sprite`." % name)
		set_process(false)
		return

	_build_frames()
	if station:
		station.item_vanished.connect(_on_item_vanished)
	_enter_state(state)


func _process(_delta: float) -> void:
	var transition: GrillState = _get_transition()
	if transition != state:
		set_state(transition)


# --- API ---

func set_state(new_state: GrillState) -> void:
	if new_state == GrillState.LAUGH and not _has_animation(new_state):
		return
	previous_state = state
	state = new_state
	_enter_state(new_state)
	state_changed.emit(previous_state, new_state)


## Estado "de descanso" da estação agora (sem contar a risada).
func get_resting_state() -> GrillState:
	if station == null or station.get_count() == 0:
		return GrillState.IDLE
	for slot in station.get_slots():
		if slot.is_occupied() and slot.get_stage() == CookingSlot.Stage.BURNT:
			return GrillState.WARNING
	return GrillState.COOKING


# --- Interno ---

func _get_transition() -> GrillState:
	# A risada vai até o fim antes de voltar ao normal.
	if state == GrillState.LAUGH and sprite.is_playing():
		return GrillState.LAUGH
	return get_resting_state()


func _enter_state(new_state: GrillState) -> void:
	var animation_name: StringName = ANIMATIONS[new_state]
	if not _has_animation(new_state):
		animation_name = ANIMATIONS[GrillState.IDLE]
		if not _has_animation(GrillState.IDLE):
			return
	sprite.play(animation_name)
	sprite.frame = 0


func _has_animation(target_state: GrillState) -> bool:
	return sprite.sprite_frames != null and sprite.sprite_frames.has_animation(ANIMATIONS[target_state])


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_sheet(frames, GrillState.IDLE, idle_sheet, idle_fps, true)
	_add_sheet(frames, GrillState.COOKING, cooking_sheet, cooking_fps, true)
	_add_sheet(frames, GrillState.WARNING, warning_sheet, warning_fps, true)
	_add_sheet(frames, GrillState.LAUGH, laugh_sheet, laugh_fps, false)
	sprite.sprite_frames = frames


func _add_sheet(frames: SpriteFrames, target_state: GrillState, sheet: Texture2D, fps: float, loop: bool) -> void:
	if sheet == null or frame_size.x <= 0:
		return
	var animation_name: StringName = ANIMATIONS[target_state]
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, fps)
	var columns: int = int(sheet.get_width() / float(frame_size.x))
	for column in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(column * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(animation_name, atlas)


func _on_item_vanished(_slot: CookingSlot, _recipe: CookingRecipe) -> void:
	set_state(GrillState.LAUGH)
