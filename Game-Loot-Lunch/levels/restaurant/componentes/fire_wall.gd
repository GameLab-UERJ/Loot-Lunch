@tool
extends StaticBody2D
class_name FireWall
## MURO DE FOGO da Brasa: um anel retangular de chamas em volta do campo.
##
## O nó fica no CENTRO do campo. `inner_size` é o tamanho da área de dentro (onde os
## jogadores ficam) e `thickness` a grossura do muro. A colisão (4 retângulos) e a
## faixa de chão queimado são desenhadas a partir desses números, então mexer no
## Inspector já mostra o muro no editor.
##
## Camada sugerida: 6 (valor 32), a mesma do balcão: o chef e a Brasa não passam,
## mas magias, invocações e arremessos passam por cima.
##
## As chamas (AnimatedSprite2D, animações "acender" e "queimar") nascem quando o jogo
## roda. `ignite()` acende em sequência, começando pelo lado mais perto da Brasa.
## Com y_sort ligado no pai (e no muro), cada chama entra na ordem de desenho junto com
## os personagens: quem está atrás do muro fica atrás das chamas. Deixe o nó do muro
## com z_index -1: a faixa de chão queimado fica embaixo de todo mundo.


signal ignited


@export var inner_size: Vector2 = Vector2(484, 212):
	set(value):
		inner_size = value
		_rebuild_shapes()
@export var thickness: float = 14.0:
	set(value):
		thickness = value
		_rebuild_shapes()

@export_group("Chamas")
@export var flame_frames: SpriteFrames
## Distância entre uma chama e outra (px).
@export var flame_spacing: float = 11.0
## Altura da arte de cada chama (a base fica na linha do muro).
@export var flame_height: float = 24.0
## Começa acesso (sem a animação de acender).
@export var lit_on_ready: bool = false
## Quem acende o muro (as chamas mais perto acendem primeiro). Vazio = o centro.
@export var ignite_source: Node2D
## Segundos para o fogo dar a volta no muro inteiro.
@export var ignite_time: float = 1.2

@export_group("Chão queimado")
@export var band_color: Color = Color(0.17, 0.08, 0.07, 1)
@export var band_edge_color: Color = Color(0.32, 0.12, 0.08, 1)
@export var ember_colors: PackedColorArray = PackedColorArray([Color(1.0, 0.55, 0.2), Color(1.0, 0.82, 0.35), Color(0.9, 0.25, 0.2)])

@export_group("Luz")
@export var light_texture: Texture2D
@export var light_spacing: float = 120.0
@export var light_color: Color = Color(1.0, 0.6, 0.3)
@export var light_energy: float = 0.8
@export var light_scale: float = 1.2


var _flames: Array[AnimatedSprite2D] = []
var _lit: bool = false


func _ready() -> void:
	_rebuild_shapes()
	if Engine.is_editor_hint():
		return
	_build_flames()
	_build_lights()
	if lit_on_ready:
		_lit = true
		for flame in _flames:
			flame.visible = true
			flame.play(&"queimar")


func is_lit() -> bool:
	return _lit


## Retângulo de DENTRO, em coordenadas locais.
func get_inner_rect() -> Rect2:
	return Rect2(-inner_size / 2.0, inner_size)


## Retângulo de dentro em coordenadas globais (útil para limitar onde se planta).
func get_inner_global_rect() -> Rect2:
	return Rect2(global_position - inner_size / 2.0, inner_size)


## Acende o muro em sequência a partir de `ignite_source`.
func ignite() -> void:
	if _lit or Engine.is_editor_hint():
		return
	_lit = true
	var origin: Vector2 = ignite_source.global_position if ignite_source else global_position
	var far: float = 1.0
	for flame in _flames:
		far = maxf(far, flame.global_position.distance_to(origin))
	for flame in _flames:
		var delay: float = flame.global_position.distance_to(origin) / far * ignite_time
		get_tree().create_timer(delay).timeout.connect(_light_flame.bind(flame))
	get_tree().create_timer(ignite_time + 0.3).timeout.connect(func() -> void: ignited.emit())


func _light_flame(flame: AnimatedSprite2D) -> void:
	if not is_instance_valid(flame):
		return
	flame.visible = true
	if flame.sprite_frames and flame.sprite_frames.has_animation(&"acender"):
		flame.play(&"acender")
		await flame.animation_finished
	if is_instance_valid(flame):
		flame.play(&"queimar")
		flame.frame = randi() % maxi(1, flame.sprite_frames.get_frame_count(&"queimar"))


# --- Montagem ------------------------------------------------------------------

func _band_rects() -> Array[Rect2]:
	var half: Vector2 = inner_size / 2.0
	var t: float = thickness
	return [
		Rect2(-half.x - t, -half.y - t, inner_size.x + t * 2.0, t),   # cima
		Rect2(-half.x - t, half.y, inner_size.x + t * 2.0, t),        # baixo
		Rect2(-half.x - t, -half.y, t, inner_size.y),                 # esquerda
		Rect2(half.x, -half.y, t, inner_size.y),                      # direita
	]


func _rebuild_shapes() -> void:
	if not is_inside_tree():
		return
	var rects: Array[Rect2] = _band_rects()
	for i in rects.size():
		var shape_node := get_node_or_null("Lado%d" % i) as CollisionShape2D
		if shape_node == null:
			shape_node = CollisionShape2D.new()
			shape_node.name = "Lado%d" % i
			add_child(shape_node)
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = rects[i].size
		shape_node.shape = rect_shape
		shape_node.position = rects[i].get_center()
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1361
	for rect in _band_rects():
		draw_rect(rect, band_color)
		draw_rect(rect, band_edge_color, false, 1.0)
		var count: int = int(rect.size.x * rect.size.y / 40.0)
		for i in count:
			var p := Vector2(rng.randf_range(rect.position.x + 1, rect.end.x - 1), rng.randf_range(rect.position.y + 1, rect.end.y - 1))
			var c: Color = ember_colors[rng.randi() % ember_colors.size()] if not ember_colors.is_empty() else Color.ORANGE
			draw_rect(Rect2(p.floor(), Vector2.ONE), c)


## Pontos da linha do meio do muro, a cada `flame_spacing`.
func _flame_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var half: Vector2 = inner_size / 2.0 + Vector2(thickness, thickness) / 2.0
	var corners: Array[Vector2] = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var steps: int = maxi(1, int(round(a.distance_to(b) / flame_spacing)))
		for k in steps:
			points.append(a.lerp(b, float(k) / steps))
	return points


func _build_flames() -> void:
	if flame_frames == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var holder := Node2D.new()
	holder.name = "Chamas"
	holder.y_sort_enabled = true
	# O nó do muro fica com z_index -1 (a faixa queimada é chão); as chamas voltam para
	# a altura dos personagens (+1 relativo = 0) e entram no y_sort com eles.
	holder.z_index = 1
	add_child(holder)
	for p in _flame_points():
		var flame := AnimatedSprite2D.new()
		flame.sprite_frames = flame_frames
		flame.position = p + Vector2(rng.randf_range(-1.5, 1.5), thickness * 0.25)
		flame.offset = Vector2(0, -flame_height / 2.0 + 2.0)
		flame.speed_scale = rng.randf_range(0.85, 1.15)
		flame.flip_h = rng.randf() < 0.5
		flame.visible = false
		holder.add_child(flame)
		_flames.append(flame)


func _build_lights() -> void:
	if light_texture == null:
		return
	var points := PackedVector2Array()
	var half: Vector2 = inner_size / 2.0 + Vector2(thickness, thickness) / 2.0
	var corners: Array[Vector2] = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var steps: int = maxi(1, int(round(a.distance_to(b) / light_spacing)))
		for k in steps:
			points.append(a.lerp(b, (float(k) + 0.5) / steps))
	for p in points:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = light_color
		light.energy = light_energy
		light.texture_scale = light_scale
		light.position = p + Vector2(0, -6)
		light.enabled = false
		add_child(light)
		ignited.connect(func() -> void: light.enabled = true)
		if lit_on_ready:
			light.enabled = true
