extends Node2D
class_name GlowHalo
## HALO: brilho redondo desenhado por código ATRÁS de um efeito (esfera, projétil,
## item...) para ele se destacar do cenário. Sem arte: círculos que pulsam.
##
## Fica como FILHO do efeito (`show_behind_parent`), então anda, cresce e some junto.
## O raio é em pixels da TELA (a escala do pai é compensada).
##
##   GlowHalo.attach(esfera, Color(0.9, 0.35, 1.0), 26.0)
##
## Reutilizável: esferas psíquicas da Rainha, carga do Raio Psíquico, qualquer efeito
## que some no fundo do cenário.


const NODE_NAME: StringName = &"GlowHalo"


@export var color: Color = Color(0.9, 0.35, 1.0, 1.0)
## Raio do brilho: pixels da TELA (com `fixed_screen_size`) ou do pai (sem).
@export var radius: float = 26.0
## true = o brilho tem sempre o mesmo tamanho na tela, mesmo que o pai cresça.
## false = cresce e encolhe junto com o pai (ex.: esfera crescendo na boca da Rainha).
@export var fixed_screen_size: bool = true
## Opacidade do miolo do brilho (a borda vai sumindo).
@export_range(0.0, 1.0) var core_alpha: float = 0.85
## Quantos círculos formam o degradê.
@export_range(2, 12) var steps: int = 6
@export var pulse_speed: float = 9.0
## Quanto o raio "respira" (0.2 = 20% maior/menor).
@export_range(0.0, 1.0) var pulse_amount: float = 0.18
## Anel na borda do brilho. Alfa 0 = sem anel.
@export var rim_color: Color = Color(1.0, 0.85, 1.0, 0.0)


var _clock: float = 0.0


## Liga o halo em `target` (cria o nó se não existir). Retorna o halo.
static func attach(target: CanvasItem, halo_color: Color, halo_radius: float,
		alpha: float = 0.85) -> GlowHalo:
	if not is_instance_valid(target):
		return null
	var halo := target.get_node_or_null(NodePath(NODE_NAME)) as GlowHalo
	if halo == null:
		halo = GlowHalo.new()
		halo.name = NODE_NAME
		target.add_child(halo)
	halo.color = halo_color
	halo.radius = halo_radius
	halo.core_alpha = alpha
	return halo


func _init() -> void:
	show_behind_parent = true


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var parent_scale: float = 1.0
	if fixed_screen_size:
		parent_scale = maxf(absf(get_global_transform().get_scale().x), 0.001)
	var pulse: float = 1.0 + pulse_amount * sin(_clock * pulse_speed)
	var outer: float = radius * pulse / parent_scale
	# Do maior (mais fraco) para o menor: os círculos se somam e o miolo fica mais forte.
	var layer_alpha: float = clampf(core_alpha * 1.6 / steps, 0.0, 1.0)
	for i in steps:
		var t: float = float(i) / steps
		var c: Color = color
		c.a = layer_alpha
		draw_circle(Vector2.ZERO, outer * (1.0 - t * 0.7), c)
	if rim_color.a > 0.0:
		draw_arc(Vector2.ZERO, outer * 0.92, 0.0, TAU, 32, rim_color, 1.5 / parent_scale)
