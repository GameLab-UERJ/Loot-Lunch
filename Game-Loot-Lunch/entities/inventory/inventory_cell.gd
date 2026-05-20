extends PanelContainer
class_name InventoryCell


@export var item : Item:
	set = set_item


@onready var item_place: TextureRect = $Panel/ItemPlace


func set_item(value : Item) -> Item:
	var previous_item : Item = item
	item = value
	if not item:
		item_place.texture = null
	elif not item.region_enabled:
		item_place.texture = item.texture
	else:
		var atlas : AtlasTexture = AtlasTexture.new()
		atlas.atlas = item.texture
		atlas.region = item.region_rect
		item_place.texture = atlas
	
	return previous_item


func remove_item() -> Item:
	var removed_item : Item = item
	item = null
	return removed_item


func is_empty() -> bool:
	return not item
