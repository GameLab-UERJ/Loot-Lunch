extends PanelContainer
class_name InventoryCell


signal wants_item_removed(cell : InventoryCell)
signal left_clicked(cell : InventoryCell)
signal split_stack(cell : InventoryCell, half : int)
@warning_ignore("unused_signal")
signal item_dropped(cell : InventoryCell, item : Item)  ## Novo: quando um item é solto nesta célula
signal item_picked(cell : InventoryCell)  ## Novo: quando um item é retirado desta célula


@export var item : Item:
	set = set_item
@export var background_color : Color = Color.hex(0x4ab5ae)
@export var selected_color : Color = Color.hex(0xd99a64)
## Se true, esta célula aceita receber itens via drag & drop
@export var can_receive_items : bool = true
## Se true, itens podem ser removidos desta célula (pickup)
@export var can_remove_items : bool = true


var count : int = 0:
	set = set_count

var _was_stackable: bool = false


@onready var item_place: TextureRect = $Panel/ItemPlace
@onready var price_label: Label = $Panel/PriceLabel
@onready var stack_label: Label = $Panel/StackCount
@onready var price_manager: PriceManager = %PriceManager


func _ready() -> void:
	item = item
	add_theme_stylebox_override("panel", StyleBoxFlat.new())
	_change_bg_color(background_color)
	price_manager.set_price_text("")
	_update_stack_label()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_released("left_click"):
		left_clicked.emit(self)
		accept_event()
	if event.is_action_released("right_click"):
		# Se não pode remover, ignora
		if not can_remove_items:
			return
		if item and _is_stackable() and count > 1:
			var half : int = count / 2
			if half > 0:
				split_stack.emit(self, half)
		else:
			wants_item_removed.emit(self)
		accept_event()


## Remove o Item Node da célula e limpa o visual
func remove_item(new_parent : Node = null, _show : bool = true, _immediate : bool = false) -> Item:
	if not new_parent:
		new_parent = get_tree().current_scene
	if not item:
		push_warning("There is no item to be removed")
		return null
	var removed_item : Item = item
	item = null
	if removed_item.get_parent():
		if _immediate:
			removed_item.reparent(new_parent)
		else:
			removed_item.call_deferred("reparent", new_parent)
	else:
		if _immediate:
			new_parent.add_child(removed_item)
		else:
			new_parent.call_deferred("add_child", removed_item)
	if _show: 
		removed_item.show()
	else:
		removed_item.hide()
	
	item_picked.emit(self)
	return removed_item


func is_stackable() -> bool:
	return _is_stackable()


func _is_stackable() -> bool:
	if item:
		return item.has_node("StackableComponent")
	return _was_stackable and count > 0


func set_item(value : Item) -> Item:
	var previous_item : Item = item
	item = value
	if not item:
		_was_stackable = false
		item_place.texture = null
		price_manager.set_price_text("")
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
	if value.get_parent():
		value.call_deferred("reparent", self)
	else:
		call_deferred("add_child",value)
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


func _change_bg_color(color : Color) -> void:
	(get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color
