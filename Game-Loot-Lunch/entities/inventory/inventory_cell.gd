extends PanelContainer
class_name InventoryCell


signal selected(cell : InventoryCell)
signal unselected(cell : InventoryCell)


@export var item : Item:
	set = set_item
@export var parent_of_removed_items : Node
@export var background_color : Color = Color.hex(0x4ab5ae)
@export var selected_color : Color = Color.hex(0xd99a64)


var is_selected : bool = false:
	set = set_is_selected


@onready var item_place: TextureRect = $Panel/ItemPlace


func _ready() -> void:
	item = item
	add_theme_stylebox_override("panel",StyleBoxFlat.new())
	change_bg_color(background_color)
	

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event : InputEventMouseButton = event
	
	if mouse_event.is_action_released("left_click"):
		is_selected = not is_selected


func change_bg_color(color : Color) -> void:
	(get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color


func set_is_selected(value : bool) -> void:
	if is_selected == value:
		return
	
	if value:
		is_selected = true
		selected.emit(self)
		change_bg_color(selected_color)
	else:
		is_selected = false
		unselected.emit(self)
		change_bg_color(background_color)
	
func set_item(value : Item) -> Item:
	var previous_item : Item = item
	item = value
	if not item:
		item_place.texture = null
		return null
	elif not item.region_enabled:
		item_place.texture = item.texture
	else:
		var atlas : AtlasTexture = AtlasTexture.new()
		atlas.atlas = item.texture
		atlas.region = item.region_rect
		item_place.texture = atlas
	value.hide()
	value.position = Vector2.ZERO
	value.reparent(self)
	return previous_item


func remove_item(new_parent : Node = null) -> Item:
	if not new_parent:
		new_parent = get_tree().current_scene
	if not item:
		push_warning("There is no item to be removed")
		return null
	var removed_item : Item = item
	item = null
	removed_item.reparent(new_parent)
	return removed_item


func is_empty() -> bool:
	return not item
