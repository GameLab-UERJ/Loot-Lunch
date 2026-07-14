extends PanelContainer
class_name InventoryCell


signal selected(cell : InventoryCell)
signal wants_item_removed(cell : InventoryCell)
signal left_clicked(cell : InventoryCell)
signal split_stack(cell : InventoryCell, half : int)


@export var item : Item:
	set = set_item
@export var background_color : Color = Color.hex(0x4ab5ae)
@export var selected_color : Color = Color.hex(0xd99a64)


var is_selected : bool = false:
	set = set_is_selected
## Quantas unidades deste item estão nesta célula.
## Para itens não-stackáveis, sempre 1.
var count : int = 0:
	set = set_count

## Cache: o Item que estava nesta célula era stackável?
## Usado quando o Item é removido (pick-up parcial) mas count > 0,
## pra não perder o label de quantidade.
var _was_stackable: bool = false


@onready var item_place: TextureRect = $Panel/ItemPlace
@onready var price_label: Label = $Panel/PriceLabel
@onready var stack_label: Label = $Panel/StackCount


func _ready() -> void:
	item = item
	add_theme_stylebox_override("panel", StyleBoxFlat.new())
	_change_bg_color(background_color)
	set_price_text("")
	_update_stack_label()


func _process(_delta: float) -> void:
	if is_selected and _get_bg_color() == background_color:
		_change_bg_color(selected_color)
	if not is_selected and _get_bg_color() == selected_color:
		_change_bg_color(background_color)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_released("left_click"):
		left_clicked.emit(self)
		accept_event()
	if event.is_action_released("right_click"):
		if item and _is_stackable() and count > 1:
			var half : int = count / 2
			if half > 0:
				split_stack.emit(self, half)
		else:
			wants_item_removed.emit(self)
		accept_event()


## Remove o Item Node da célula e limpa o visual (count vira 0).
## Usado para remoção completa (não-stackável ou stack inteiro).
func remove_item(new_parent : Node = null, _show : bool = true, _immediate : bool = false) -> Item:
	if not new_parent:
		new_parent = get_tree().current_scene
	if not item:
		push_warning("There is no item to be removed")
		return null
	var removed_item : Item = item
	item = null
	if _immediate:
		removed_item.reparent(new_parent)
	else:
		removed_item.call_deferred("reparent", new_parent)
	if _show: 
		removed_item.show()
	else:
		removed_item.hide()
	return removed_item


## Remove o Item Node da célula mas MANTÉM o visual (textura + count).
## Usado quando vc pega 1 unidade de um stack — a célula continua
## mostrando o ícone e o número de unidades restantes.
func is_stackable() -> bool:
	return _is_stackable()


func _is_stackable() -> bool:
	if item:
		return item.has_node("StackableComponent")
	return _was_stackable and count > 0


func set_is_selected(value : bool) -> void:
	is_selected = value
	if is_selected:
		selected.emit(self)


func set_item(value : Item) -> Item:
	var previous_item : Item = item
	item = value
	if not item:
		_was_stackable = false
		item_place.texture = null
		set_price_text("")
		count = 0
		return null
	else:
		_was_stackable = item.has_node("StackableComponent")
		if not item.region_enabled:
			item_place.texture = item.texture
		else:
			var atlas : AtlasTexture = AtlasTexture.new()
			atlas.atlas = item.texture
			atlas.region = item.region_rect
			item_place.texture = atlas
	value.hide()
	value.force_stop_follow_mouse()
	value.top_level = false
	value.z_index = 0
	value.position = Vector2.ZERO
	value.call_deferred("reparent", self)
	count = 1
	return previous_item


func set_count(value : int) -> void:
	count = max(0, value)
	_update_stack_label()


func _update_stack_label() -> void:
	if not is_inside_tree():
		return
	if _is_stackable() and count > 1:
		stack_label.text = str(count)
		stack_label.show()
	else:
		stack_label.hide()


func set_price_text(value : String, color : Color = Color.WHITE) -> void:
	price_label.text = "$ " + value
	if price_label.label_settings:
		price_label.label_settings = price_label.label_settings.duplicate()
		price_label.label_settings.font_color = color
	price_label.add_theme_color_override("font_color", color)
	price_label.visible = not value.is_empty()


func _change_bg_color(color : Color) -> void:
	(get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color


func _get_bg_color() -> Color:
	return (get_theme_stylebox("panel") as StyleBoxFlat).bg_color
