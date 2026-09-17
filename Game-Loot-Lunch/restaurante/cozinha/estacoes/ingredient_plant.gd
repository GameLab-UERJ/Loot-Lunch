extends IngredientCrate
class_name IngredientPlant
## Pé de ingrediente (ex.: pé de cogumelo). Igual à caixa, mas depois de dar um item
## precisa regenerar: fica escuro, mostra uma barrinha e só volta a dar item quando o
## CooldownComponent termina. Ao regenerar, toca o efeito (SpriteSheetEffect).
##
## Filhos esperados: Sprite2D, CooldownComponent, InteractableComponent e (opcional) EfeitoRegenerou.


## Cor aplicada ao sprite enquanto o pé está regenerando.
@export var regrowing_modulate: Color = Color(0.45, 0.45, 0.45, 1.0)

@export_group("Barra de progresso")
@export var show_progress_bar: bool = true
@export var progress_bar_offset: Vector2 = Vector2(-12, 16)
@export var progress_bar_size: Vector2 = Vector2(24, 3)
@export var progress_bar_color: Color = Color(0.72, 0.4, 0.95, 1.0)


@onready var cooldown: CooldownComponent = $CooldownComponent
@onready var visual: CanvasItem = get_node_or_null("Sprite2D")
@onready var regrow_effect: SpriteSheetEffect = get_node_or_null("EfeitoRegenerou")


func _ready() -> void:
	super()
	cooldown.finished.connect(_on_cooldown_finished)
	set_process(false)


func _process(_delta: float) -> void:
	queue_redraw()


func is_regrowing() -> bool:
	return not cooldown.is_ready()


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if is_regrowing():
		return
	if give_item(actor_hand):
		_start_regrowing()


func _start_regrowing() -> void:
	interactable.enabled = false
	# self_modulate para não brigar com o highlight, que usa `modulate`.
	if visual:
		visual.self_modulate = regrowing_modulate
	set_process(show_progress_bar)
	cooldown.start()


func _on_cooldown_finished() -> void:
	interactable.enabled = true
	if visual:
		visual.self_modulate = Color.WHITE
	set_process(false)
	queue_redraw()
	if regrow_effect:
		regrow_effect.play_once()


func _draw() -> void:
	if not show_progress_bar or not is_regrowing():
		return
	var back := Rect2(progress_bar_offset, progress_bar_size)
	draw_rect(back, Color(0, 0, 0, 0.6))
	var fill := back
	fill.size.x *= cooldown.get_progress()
	draw_rect(fill, progress_bar_color)
