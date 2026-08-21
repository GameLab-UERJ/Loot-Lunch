extends CanvasLayer
class_name Hud

## Ícones dos botões — podem ser trocados pelo editor. Se vazios, o botão aparece sem ícone.
@export var mission_icon: Texture2D
@export var inventory_icon: Texture2D


@onready var life_bar: TextureProgressBar = $LifeBar
@onready var gold_label: Label = $GoldBox/GoldLabel
@onready var mission_button: Button = $ButtonsBox/MissionButton
@onready var inventory_button: Button = $ButtonsBox/InventoryButton
@onready var button_click: AudioStreamPlayer = $ButtonClick


var _player: Player
var _player_max_hp: int = 1
var _life_bar_tween: Tween
var _flash_tween: Tween
var _notification_tweens: Dictionary = {}


func _ready() -> void:
	if mission_icon:
		mission_button.icon = mission_icon
	if inventory_icon:
		inventory_button.icon = inventory_icon

	if PlayerWallet.gold_changed.is_connected(_on_gold_changed) == false:
		PlayerWallet.gold_changed.connect(_on_gold_changed)
	_update_gold(PlayerWallet.gold)

	if not QuestManager.mission_updated.is_connected(_on_mission_updated):
		QuestManager.mission_updated.connect(_on_mission_updated)

	var player := get_parent() as Player
	if player:
		_bind_player(player)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		return

	var parent := get_parent()
	if parent is Player:
		_bind_player(parent)
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	var player := scene.find_child("Player", true, false) as Player
	if player:
		_bind_player(player)


func _bind_player(player: Player) -> void:
	_player = player
	_player_max_hp = maxi(1, player.hp)
	life_bar.max_value = _player_max_hp
	life_bar.value = clampf(_player.hp, 0, _player_max_hp)

	if not player.took_damage.is_connected(_on_player_took_damage):
		player.took_damage.connect(_on_player_took_damage)

	var inventory_component := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory_component and inventory_component.inventory \
			and not inventory_component.inventory.item_added.is_connected(_on_item_added):
		inventory_component.inventory.item_added.connect(_on_item_added)


func _animate_life_bar() -> void:
	if not is_instance_valid(_player):
		return

	var target := clampf(_player.hp, 0, _player_max_hp)
	var previous := life_bar.value
	if is_equal_approx(previous, target):
		return

	if _life_bar_tween and _life_bar_tween.is_valid():
		_life_bar_tween.kill()
	_life_bar_tween = create_tween()
	_life_bar_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_life_bar_tween.tween_property(life_bar, "value", target, 0.35)

	if target < previous:
		_flash_life_bar(Color(1.0, 0.35, 0.3))
	else:
		_flash_life_bar(Color(0.35, 1.0, 0.45))


func _flash_life_bar(color: Color) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	life_bar.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.15)
	_flash_tween.tween_property(life_bar, "modulate", Color.WHITE, 0.3)


func _update_gold(amount: int) -> void:
	gold_label.text = str(amount)


func _on_gold_changed(amount: int) -> void:
	_update_gold(amount)


func _on_player_took_damage() -> void:
	_animate_life_bar()


func _on_mission_updated(_new_stage: int) -> void:
	_start_notification_blink(mission_button)


func _on_item_added(_item: Item) -> void:
	var inventory_component : InventoryComponent = _player.get_node_or_null("InventoryComponent") as InventoryComponent
	if (inventory_component and 
		inventory_component.inventory.current_item_added_source == 
		Inventory.ItemAddSource.PICK_UP):
			_start_notification_blink(inventory_button)
	print("blink attempt: ",Inventory.ItemAddSource.find_key(inventory_component.inventory.current_item_added_source))


func _start_notification_blink(button: Button) -> void:
	_stop_notification_blink(button)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(button, "modulate:a", 0.15, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "modulate:a", 1.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_notification_tweens[button] = tween


func _stop_notification_blink(button: Button) -> void:
	var tween: Tween = _notification_tweens.get(button) as Tween
	if tween != null:
		tween.kill()
	_notification_tweens.erase(button)
	button.modulate = Color.WHITE


func _on_mission_button_pressed() -> void:
	button_click.play(0.13)
	_stop_notification_blink(mission_button)
	var pause_menu := get_tree().root.get_node_or_null("PauseMenu") as PauseMenu
	if pause_menu:
		pause_menu.pause()
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	pause_menu = scene.get_node_or_null("PauseMenu") as PauseMenu
	if pause_menu:
		pause_menu.pause()


func _on_inventory_button_pressed() -> void:
	button_click.play(0.13)
	_stop_notification_blink(inventory_button)
	var player := get_parent() as Player
	if player == null:
		return

	var inventory_component := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory_component == null or inventory_component.inventory == null:
		return

	inventory_component.toggle_inventory()
