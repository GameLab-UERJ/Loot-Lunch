extends Node

signal game_state_saved
signal game_state_loaded

var current_workbench: Workbench.Type = Workbench.Type.None

var current_scene_path: String = ""
var player_position: Vector2 = Vector2.ZERO
var inventory_data: Array[Dictionary] = []
var time_state: int = TimeCycle.TimeState.DAY
var time_remaining: float = 0.0
var day_night_color: Color = Color.WHITE
var quest_status: int = QuestManager.QuestStatus.NAO_INICIADA

var _is_loading_save: bool = false
var _is_transitioning: bool = false


func collect_game_state() -> void:
	_collect_scene()
	_collect_player_position()
	_collect_inventory()
	_collect_time_state()
	_collect_quest_status()


func _collect_scene() -> void:
	current_scene_path = get_tree().current_scene.scene_file_path


func _collect_player_position() -> void:
	var player: Player = _find_player()
	if player:
		player_position = player.global_position


func _collect_inventory() -> void:
	inventory_data = []
	var inventory: Inventory = _find_inventory()
	if not inventory:
		return
	for cell: InventoryCell in inventory.grid.get_children():
		if cell.item:
			var item_data: Dictionary = {
				"scene_path": cell.item.scene_file_path,
				"item_name": cell.item.item_name,
				"count": cell.count,
			}
			inventory_data.append(item_data)


func _collect_time_state() -> void:
	time_state = TimeCycle.current_state
	time_remaining = TimeCycle.get_time_remaining()
	day_night_color = DayNightCycle.color


func _collect_quest_status() -> void:
	quest_status = QuestManager.current_status


func apply_game_state() -> void:
	_apply_time_state()
	_apply_quest_status()
	game_state_loaded.emit()


func schedule_restore_after_load() -> void:
	_is_loading_save = true


func save_transition_state() -> void:
	_is_transitioning = true
	_collect_inventory()


func restore_if_transitioning() -> void:
	if not _is_transitioning:
		return
	_is_transitioning = false
	call_deferred("_apply_deferred_transition_restore")


func _apply_deferred_transition_restore() -> void:
	restore_inventory()


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if _is_loading_save and node.get_parent() == get_tree().root:
		_is_loading_save = false
		call_deferred("_apply_deferred_restore")


func _apply_deferred_restore() -> void:
	apply_game_state()
	restore_inventory()
	restore_player_position()
	game_state_saved.emit()


func _apply_time_state() -> void:
	TimeCycle.change_state(time_state as TimeCycle.TimeState)
	TimeCycle.set_time_remaining(time_remaining)
	DayNightCycle.color = day_night_color


func _apply_quest_status() -> void:
	QuestManager.current_status = quest_status as QuestManager.QuestStatus
	QuestManager.mission_updated.emit(QuestManager.current_status)


func restore_inventory() -> void:
	var inventory: Inventory = _find_inventory()
	if not inventory:
		return
	for cell: InventoryCell in inventory.grid.get_children():
		if cell.item:
			cell.item.queue_free()
			cell.item = null
			cell.count = 0
	for item_data: Dictionary in inventory_data:
		if ResourceLoader.exists(item_data["scene_path"]):
			var item_scene: PackedScene = load(item_data["scene_path"])
			if item_scene:
				var item: Item = item_scene.instantiate()
				item.dropped_count = item_data["count"]
				add_child(item)
				inventory.add_item(item)


func restore_player_position() -> void:
	var player: Player = _find_player()
	if player:
		player.global_position = player_position


func _find_player() -> Player:
	var players: Array[Node] = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		return players[0] as Player
	return _find_player_recursive(get_tree().current_scene)


func _find_player_recursive(node: Node) -> Player:
	if node is Player:
		return node as Player
	for child: Node in node.get_children():
		var result: Player = _find_player_recursive(child)
		if result:
			return result
	return null


func _find_inventory() -> Inventory:
	var inventories: Array[Node] = get_tree().get_nodes_in_group("Inventory")
	if inventories.size() > 0:
		return inventories[0] as Inventory
	return _find_inventory_recursive(get_tree().current_scene)


func _find_inventory_recursive(node: Node) -> Inventory:
	if node is Inventory:
		return node as Inventory
	for child: Node in node.get_children():
		var result: Inventory = _find_inventory_recursive(child)
		if result:
			return result
	return null
