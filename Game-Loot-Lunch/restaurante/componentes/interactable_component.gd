extends Area2D
class_name InteractableComponent
## Coloque em qualquer coisa da cozinha que reage à interação (clique DIREITO do mouse)
## (bancada, caixa de ingredientes, fogão, lixeira, balcão de entrega...).
## A lógica fica no dono, conectado ao sinal `interacted`.
##
## Dois destaques independentes no `highlight_target`:
##   - FOCO  (jogador perto e virado para ele): clareia o sprite (modulate).
##   - HOVER (mouse em cima): silhueta BRANCA em volta da arte. Mais apagada
##     quando o jogador ainda está longe demais para interagir.
##
## Camada sugerida: collision_layer = 8 (camada 4 "interactables"), mask = 0.


signal interacted(actor: Node)
## Ação SECUNDÁRIA (tecla T): descartar/limpar. Quem não usa simplesmente ignora.
signal alt_interacted(actor: Node)
signal focus_changed(is_focused: bool)
signal hover_changed(is_hovered: bool)


@export var enabled: bool = true
## Nó que brilha quando o jogador está mirando nele (opcional).
@export var highlight_target: CanvasItem
@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)

@export_group("Silhueta (mouse em cima)")
@export var outline_color: Color = Color.WHITE
## Largura da silhueta em pixels da TELA (a escala do sprite é compensada).
@export var outline_width: float = 1.0
## Transparência da silhueta quando o jogador ainda está longe demais.
@export_range(0.0, 1.0) var out_of_reach_alpha: float = 0.4


const OUTLINE_SHADER: Shader = preload("res://restaurante/componentes/hover_outline.gdshader")


var is_focused: bool = false
var is_hovered: bool = false
var _original_modulate: Color = Color.WHITE
var _original_material: Material = null
var _outline_material: ShaderMaterial = null


func _ready() -> void:
	if highlight_target:
		_original_modulate = highlight_target.modulate
		_original_material = highlight_target.material


func can_interact(_actor: Node) -> bool:
	return enabled


func interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false
	interacted.emit(actor)
	return true


## Ação secundária (tecla T). Mesma regra de `interact`, outro sinal.
func alt_interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false
	alt_interacted.emit(actor)
	return true


func set_focused(value: bool) -> void:
	if is_focused == value:
		return
	is_focused = value
	_refresh_modulate()
	focus_changed.emit(value)


## Mouse em cima (ou não). `in_reach` = o jogador já consegue interagir daqui.
func set_hovered(value: bool, in_reach: bool = true) -> void:
	var changed: bool = is_hovered != value
	is_hovered = value
	_apply_outline(in_reach)
	if changed:
		hover_changed.emit(value)


func _apply_outline(in_reach: bool) -> void:
	if highlight_target == null:
		return
	_refresh_modulate()
	if not is_hovered or not _target_has_texture():
		highlight_target.material = _original_material
		return
	if _outline_material == null:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = OUTLINE_SHADER
	var color: Color = outline_color
	if not in_reach:
		color.a *= out_of_reach_alpha
	_outline_material.set_shader_parameter(&"outline_color", color)
	_outline_material.set_shader_parameter(&"width", _outline_width_in_texture())
	highlight_target.material = _outline_material


## Foco clareia o sprite. Sem textura (ex.: Polygon2D de teste) não dá para
## desenhar silhueta, então o hover também só clareia.
func _refresh_modulate() -> void:
	if highlight_target == null:
		return
	var lit: bool = is_focused or (is_hovered and not _target_has_texture())
	highlight_target.modulate = highlight_modulate if lit else _original_modulate


func _target_has_texture() -> bool:
	return highlight_target is Sprite2D or highlight_target is AnimatedSprite2D


## Converte a largura de pixels da tela para pixels da textura (sprites encolhidos
## com scale 0.25 precisam de um contorno 4x maior na textura).
func _outline_width_in_texture() -> float:
	var node2d := highlight_target as Node2D
	if node2d == null:
		return outline_width
	var scale_factor: float = maxf(absf(node2d.global_scale.x), 0.01)
	return outline_width / scale_factor
