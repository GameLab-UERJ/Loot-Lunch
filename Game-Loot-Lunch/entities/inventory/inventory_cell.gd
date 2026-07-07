extends PanelContainer
class_name InventoryCell


signal selected(cell : InventoryCell)
signal wants_item_removed(cell : InventoryCell)
signal left_clicked(cell : InventoryCell)


@export var item : Item:
	set = set_item
@export var background_color : Color = Color.hex(0x4ab5ae)
@export var selected_color : Color = Color.hex(0xd99a64)


var is_selected : bool = false:
	set = set_is_selected


@onready var item_place: TextureRect = $Panel/ItemPlace
@onready var price_label: Label = $Panel/PriceLabel


func _ready() -> void:
	item = item
	add_theme_stylebox_override("panel",StyleBoxFlat.new())
	_change_bg_color(background_color)
	set_price_text("")


func _process(_delta: float) -> void:
	if is_selected and _get_bg_color() == background_color:
		_change_bg_color(selected_color)
	if not is_selected and _get_bg_color() == selected_color:
		_change_bg_color(background_color)
	

func _gui_input(event: InputEvent) -> void:
	if event.is_action_released("left_click"):
		left_clicked.emit(self)
	if event.is_action_released("right_click"):
		wants_item_removed.emit(self)


func remove_item(new_parent : Node = null, _show : bool = true) -> Item:
	if not new_parent:
		new_parent = get_tree().current_scene
	if not item:
		push_warning("There is no item to be removed")
		return null
	var removed_item : Item = item
	item = null
	removed_item.call_deferred("reparent",new_parent)
	if _show: 
		removed_item.show()
	else:
		removed_item.hide()
	return removed_item


func set_is_selected(value : bool) -> void:
	is_selected = value
	if is_selected:
		selected.emit(self)


func set_item(value : Item) -> Item:
	var previous_item : Item = item
	item = value
	if not item:
		item_place.texture = null
		set_price_text("")
		return null
	elif not item.region_enabled:
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
	return previous_item


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
