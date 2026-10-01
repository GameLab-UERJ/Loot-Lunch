extends Node2D
class_name SpriteOutline
## Silhueta (contorno de UMA cor) em volta de um Sprite2D ou AnimatedSprite2D.
##
## Fica como FILHO do sprite, desenhada ATRÁS dele (`show_behind_parent`): repete a
## arte do quadro atual várias vezes, deslocada em volta e pintada de uma cor só.
## O que sobra para fora da arte é a silhueta.
##
## Diferente do `hover_outline.gdshader` (que pinta dentro do próprio quadro), aqui o
## contorno não é cortado na borda do quadro. Por isso serve para spritesheets com a
## arte encostada na borda, como o espetinho girando (16x16).
##
## Reutilizável: espetinho que vai sair da churrasqueira, item que o jogador vai pegar,
## cliente selecionado...
##
## Uso por código (o normal):
##   SpriteOutline.show_on(sprite, Color.WHITE)   # liga (cria o nó se não existir)
##   SpriteOutline.hide_on(sprite)                # desliga (remove o nó)


const NODE_NAME: StringName = &"SpriteOutline"
const FILL_SHADER: Shader = preload("res://restaurante/componentes/silhouette_fill.gdshader")


## Cor da silhueta.
@export var color: Color = Color.WHITE: set = set_color
## Largura em pixels da TELA (a escala do sprite é compensada).
@export var width: float = 1.0


var _material: ShaderMaterial


## Liga a silhueta em `target` (Sprite2D ou AnimatedSprite2D). Retorna o nó criado/achado.
static func show_on(target: CanvasItem, outline_color: Color = Color.WHITE, outline_width: float = 1.0) -> SpriteOutline:
	if not is_instance_valid(target):
		return null
	var outline := target.get_node_or_null(NodePath(NODE_NAME)) as SpriteOutline
	if outline == null:
		outline = SpriteOutline.new()
		outline.name = NODE_NAME
		target.add_child(outline)
	outline.width = outline_width
	outline.color = outline_color
	return outline


## Tira a silhueta de `target` (se tiver).
static func hide_on(target: CanvasItem) -> void:
	if not is_instance_valid(target):
		return
	var outline: Node = target.get_node_or_null(NodePath(NODE_NAME))
	if outline:
		target.remove_child(outline)
		outline.queue_free()


static func is_shown_on(target: CanvasItem) -> bool:
	return is_instance_valid(target) and target.get_node_or_null(NodePath(NODE_NAME)) != null


func _init() -> void:
	show_behind_parent = true
	_material = ShaderMaterial.new()
	_material.shader = FILL_SHADER
	material = _material
	set_color(color)


func _process(_delta: float) -> void:
	# A arte do pai pode trocar de quadro a qualquer momento (animação).
	queue_redraw()


func set_color(value: Color) -> void:
	color = value
	if _material:
		_material.set_shader_parameter(&"tint", color)
	queue_redraw()


func _draw() -> void:
	var frame: Dictionary = _current_frame()
	if frame.is_empty():
		return
	var texture: Texture2D = frame.texture
	var source: Rect2 = frame.source
	var rect := Rect2(frame.top_left, source.size)
	var radius: int = _width_in_texture()

	draw_set_transform(Vector2.ZERO, 0.0, frame.flip)
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			if dx * dx + dy * dy > radius * radius + radius:
				continue
			var shifted := Rect2(rect.position + Vector2(dx, dy), rect.size)
			if source.position == Vector2.ZERO and source.size == texture.get_size():
				draw_texture_rect(texture, shifted, false)
			else:
				draw_texture_rect_region(texture, shifted, source)
	draw_set_transform(Vector2.ZERO)


## Textura + recorte + posição do quadro que o pai está mostrando agora.
func _current_frame() -> Dictionary:
	var parent: Node = get_parent()
	var texture: Texture2D = null
	var source := Rect2()
	var centered: bool = true
	var offset := Vector2.ZERO
	var flip := Vector2.ONE

	if parent is AnimatedSprite2D:
		var animated := parent as AnimatedSprite2D
		if animated.sprite_frames == null or not animated.sprite_frames.has_animation(animated.animation):
			return {}
		if animated.sprite_frames.get_frame_count(animated.animation) == 0:
			return {}
		texture = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		if texture:
			source = Rect2(Vector2.ZERO, texture.get_size())
		centered = animated.centered
		offset = animated.offset
		flip = Vector2(-1.0 if animated.flip_h else 1.0, -1.0 if animated.flip_v else 1.0)
	elif parent is Sprite2D:
		var sprite := parent as Sprite2D
		texture = sprite.texture
		if texture == null:
			return {}
		if sprite.region_enabled:
			source = sprite.region_rect
		else:
			source = Rect2(Vector2.ZERO, texture.get_size())
		if sprite.hframes > 1 or sprite.vframes > 1:
			var cell := source.size / Vector2(sprite.hframes, sprite.vframes)
			source = Rect2(source.position + cell * Vector2(sprite.frame_coords), cell)
		centered = sprite.centered
		offset = sprite.offset
		flip = Vector2(-1.0 if sprite.flip_h else 1.0, -1.0 if sprite.flip_v else 1.0)
	else:
		return {}

	if texture == null:
		return {}
	var top_left: Vector2 = offset - (source.size * 0.5 if centered else Vector2.ZERO)
	if centered:
		top_left = top_left.floor()
	return {"texture": texture, "source": source, "top_left": top_left, "flip": flip}


## Largura da tela convertida para pixels da textura (sprite com scale 0.25 precisa de 4).
func _width_in_texture() -> int:
	var scale_factor: float = maxf(absf(global_scale.x), 0.01)
	return maxi(int(ceil(width / scale_factor - 0.001)), 1)
