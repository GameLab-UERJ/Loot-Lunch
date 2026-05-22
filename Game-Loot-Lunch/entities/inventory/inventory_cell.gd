extends PanelContainer
class_name InventoryCell


signal selected(cell : InventoryCell)
signal unselected(cell : InventoryCell)


@export var item : Item:
	set = set_item
@export var parent_of_removed_items : Node
@export var background_color : Color = Color.hex(0x4ab5ae)
@export var selected_color : Color = Color.hex(0xd99a64)


var can_select : bool = true
var is_selected : bool = false:
	set = set_is_selected


@onready var item_place: TextureRect = $Panel/ItemPlace


func _ready() -> void:
	item = item
	add_theme_stylebox_override("panel",StyleBoxFlat.new())
	change_bg_color(background_color)


func _process(delta: float) -> void:
	if is_selected and get_bg_color() == background_color:
		change_bg_color(selected_color)
	if not is_selected and get_bg_color() == selected_color:
		change_bg_color(background_color)
	

func _gui_input(event: InputEvent) -> void:
	if not can_select:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event : InputEventMouseButton = event
	
	if mouse_event.is_action_released("left_click"):
		set_is_selected(true)


func change_bg_color(color : Color) -> void:
	(get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color


func get_bg_color() -> Color:
	return (get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func set_is_selected(value : bool) -> void:
	is_selected = value
	if is_selected:
		selected.emit(self)
	else:
		unselected.emit(self)


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
	value.force_stop_follow_mouse()
	value.position = Vector2.ZERO
	value.reparent(self)
	return previous_item


func remove_item(new_parent : Node = null, _show : bool = true) -> Item:
	if not new_parent:
		new_parent = get_tree().current_scene
	if not item:
		push_warning("There is no item to be removed")
		return null
	var removed_item : Item = item
	item = null
	removed_item.reparent(new_parent)
	if _show: 
		removed_item.show()
	else:
		removed_item.hide()
	return removed_item


func is_empty() -> bool:
	return not item
