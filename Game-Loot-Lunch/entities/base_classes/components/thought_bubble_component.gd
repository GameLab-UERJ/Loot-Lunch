extends Node2D
class_name ThoughtBubbleComponent
## Balão de pensamento GENÉRICO: mostra N ícones dentro de um balão, com aura colorida opcional.
## Não sabe o que é pedido, carne ou cogumelo — quem usa passa as texturas e a cor.
##
## Reutilizável: pedido do cliente, "estou com sede", ideia de um NPC, dica de receita...
##
## Posicione ESTE nó onde fica a ponta do rabinho do balão (ex.: em cima da cabeça do cliente).
## O balão cresce a partir desse ponto quando aparece.
##
## Estrutura esperada:
##   ThoughtBubble (este script)
##   └── Conteudo  (Node2D)  -> é ele que anima (escala/balanço)
##       ├── Aura   (Sprite2D, material aura_outline.gdshader)  [opcional]
##       ├── Balao  (Sprite2D, textura do balão)
##       └── Icones (Node2D)  -> os ícones são criados aqui por código


signal bubble_shown
signal bubble_hidden


@export_group("Arte (pixels da textura, relativos ao centro dela)")
## Onde fica a ponta do rabinho do balão. É o ponto que fica "preso" na cabeça.
@export var tail_tip: Vector2 = Vector2(-27, 26)
## Centro da área onde os ícones ficam.
@export var content_center: Vector2 = Vector2(0, -5)
## Distância entre o centro de um ícone e o do próximo.
@export var icon_spacing: float = 22.0
@export var icon_scale: Vector2 = Vector2.ONE

@export_group("Animação")
## Começa escondido (o normal: só aparece quando alguém chama `appear()`).
@export var start_hidden: bool = true
@export var pop_time: float = 0.18
## Balanço vertical enquanto está visível, em pixels da textura. 0 desliga.
@export var bob_amplitude: float = 1.5
@export var bob_speed: float = 3.0


var _shown: bool = false
var _tween: Tween
var _time: float = 0.0


@onready var content: Node2D = $Conteudo
@onready var balloon: Sprite2D = $Conteudo/Balao
@onready var aura: Sprite2D = get_node_or_null("Conteudo/Aura")
@onready var icons_root: Node2D = $Conteudo/Icones


func _ready() -> void:
	_layout()
	if start_hidden:
		visible = false
		content.scale = Vector2.ZERO
	else:
		_shown = true
	if aura:
		aura.visible = false


func _process(delta: float) -> void:
	if not visible or is_zero_approx(bob_amplitude):
		return
	_time += delta
	# Arredonda para não "tremer" meio pixel na pixel art.
	content.position.y = roundf(sin(_time * bob_speed) * bob_amplitude)


# --- API pública ---

## Troca os ícones do balão. Passe uma lista de Texture2D (pode repetir a mesma).
func set_icons(textures: Array) -> void:
	for child in icons_root.get_children():
		icons_root.remove_child(child)
		child.queue_free()

	var count: int = textures.size()
	for i in count:
		var icon := Sprite2D.new()
		icon.name = "Icone%d" % (i + 1)
		icon.texture = textures[i]
		icon.scale = icon_scale
		icon.position.x = roundf((i - (count - 1) * 0.5) * icon_spacing)
		icons_root.add_child(icon)


## Liga a aura com a cor dada (ex.: verde = no ponto, vermelho = torrado).
func set_aura(color: Color) -> void:
	if aura == null:
		return
	aura.self_modulate = color
	aura.visible = true


func clear_aura() -> void:
	if aura:
		aura.visible = false


func is_shown() -> bool:
	return _shown


## Mostra o balão com um "pop" saindo da ponta do rabinho.
func appear() -> void:
	if _shown:
		return
	_shown = true
	visible = true
	_time = 0.0
	_restart_tween()
	content.scale = Vector2(0.2, 0.2)
	content.modulate.a = 0.0
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(content, "scale", Vector2.ONE, pop_time)
	_tween.parallel().tween_property(content, "modulate:a", 1.0, pop_time * 0.6)
	bubble_shown.emit()


## Esconde o balão encolhendo de volta para a ponta do rabinho.
func disappear() -> void:
	if not _shown:
		return
	_shown = false
	_restart_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(content, "scale", Vector2(0.2, 0.2), pop_time * 0.8)
	_tween.parallel().tween_property(content, "modulate:a", 0.0, pop_time * 0.8)
	_tween.tween_callback(func() -> void: visible = false)
	bubble_hidden.emit()


# --- Interno ---

## Posiciona as peças para que a ponta do rabinho fique na origem deste nó.
func _layout() -> void:
	balloon.position = -tail_tip
	if aura:
		aura.position = -tail_tip
		if aura.texture == null:
			aura.texture = balloon.texture
	icons_root.position = content_center - tail_tip


func _restart_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
