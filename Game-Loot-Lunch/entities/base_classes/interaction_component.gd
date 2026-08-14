extends Label
class_name InteractionComponent


@export var outlined_node : Node2D:
	set(value):
		outlined_node = value
		print(outlined_node)
		if outlined_node:
			outlined_node.material = load("res://resources/shaders/outline_material.tres").duplicate_deep()
			outlined_node.material.set("shader_parameter/outline_color",Color.WHITE)
			outlined_node.material.set("shader_parameter/width",0)


func _ready() -> void:
	set_properties()
	set_canvas_item_properties()
	set_layout_properties()
	set_theme_overrides_properties()
	if not outlined_node:
		find_outlined_node()
	outlined_node = outlined_node


func set_properties() -> void:
	text = 'E'
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD


func set_canvas_item_properties() -> void:
	visible = false
	z_index = 5


func set_layout_properties() -> void:
	custom_minimum_size = Vector2(200,200)
	set_anchors_preset(Control.PRESET_CENTER)
	size = Vector2(200,200)
	position = Vector2(-29,-50)
	scale = Vector2.ONE*0.3
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func set_theme_overrides_properties() -> void:
	#Colors
	add_theme_color_override("font_outline_color",Color.BLACK)
	add_theme_color_override("font_shadow_color",Color.BLACK)
	#Constants
	add_theme_constant_override("line_spacing",3)
	add_theme_constant_override("shadow_offset_x",2)
	add_theme_constant_override("shadow_offset_y",2)
	add_theme_constant_override("outline_size",5)
	#Fonts
	add_theme_font_override("font",load("res://assets/fonts/ui/Sta.Toasty_font (1).ttf"))
	#Fonts Sizes
	add_theme_font_size_override("font_size",36)


func show_interaction() -> void:
	if not outlined_node:
		find_outlined_node()
	if outlined_node:
		outlined_node.material.set("shader_parameter/width",1)
	show()


func hide_interaction() -> void:
	if outlined_node:
		outlined_node.material.set("shader_parameter/width",0)
	hide()


func find_outlined_node() -> void:
	for node : Node in get_parent().get_children():
		if is_instance_of(node,Sprite2D) or is_instance_of(node,AnimatedSprite2D):
			outlined_node = node
			break
	
