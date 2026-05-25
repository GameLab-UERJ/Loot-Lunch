extends Control

class_name SaveLoadMenu

signal save_load_menu_exit()

var save_name_menu: SaveTitleMenu
var save_name_scene: PackedScene = preload("res://menus/saver_loader/save_title_menu.tscn")

var save_info: Array
var save_slot: int = -1

@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var hover_audio: AudioStreamPlayer = $HoverAudio

@onready var save_slot_on: Button = $Panel/HBoxContainer/VBoxContainer/SavesGridContainer/SaveSlot0
@onready var saves_grid_container: GridContainer = $Panel/HBoxContainer/VBoxContainer/SavesGridContainer

@onready var h_box_container: HBoxContainer = $Panel/HBoxContainer

@onready var actions_grid_container: GridContainer = $Panel/HBoxContainer/VBoxContainer/ActionsGridContainer
@onready var title: Label = $Panel/HBoxContainer/VBoxContainer/Title


func _ready() -> void:
	_save_slots_update()
	
	if get_parent().name == "MainMenu":
		title.text = "Load"


func _on_save_button_pressed() -> void:
	if save_slot == -1:
		return
	
	# Goes to scene where it gets the new save title
	_go_save_title_menu()

	_on_mouse_pressed()


func _on_load_button_pressed() -> void:
	if SaveLoadManager.saves_info[save_slot][0] == "VAZIO" or save_slot == -1:
		return
		
	SaveLoadManager.load_data(SaveLoadManager.saves_info[save_slot][0] + ".tres")
	
	print(SaveLoadManager.SaveFileData.save_name)
	
	_on_mouse_pressed()


func _on_erase_button_pressed() -> void:
	if SaveLoadManager.saves_info[save_slot][0] == "VAZIO" or save_slot == -1:
		return
	
	SaveLoadManager.erase_data(save_slot)
	
	_save_slots_update()
	action_buttons_state()
	_on_mouse_pressed()


func _on_return_button_pressed() -> void:
	# Used to exit the scene
	save_load_menu_exit.emit()
	
	if press_audio == null:
		return
	
	visible = false
	
	press_audio.play()
	await press_audio.finished
	
	queue_free()


# -- Makes only one save slot selected at time --
func _on_save_slot_toggled(toggled_on: bool, slot_path: NodePath, save_position: int) -> void:
	if toggled_on:
		save_slot = save_position
		
		# Used to avoid multi click on the same slot
		save_slot_on.disabled = false
		save_slot_on = get_node(slot_path)
		save_slot_on.disabled = true
		
		action_buttons_state()
		_on_mouse_pressed()
		
		print(SaveLoadManager.saves_info[save_position][0])


# -- Effect when mouse enters any element --
func _on_mouse_entered() -> void:
	if hover_audio == null:
		return
		
	hover_audio.play()
	await hover_audio.finished


# -- Effect when mouse clicks any element --
func _on_mouse_pressed() -> void:
	if press_audio == null:
		return
	
	press_audio.play()
	await press_audio.finished


# -- Puts basic information of the saves in the slots --
func _save_slots_update() -> void:
	for i in range(6):
		if SaveLoadManager.saves_info[i][0] != "VAZIO":
			save_info = [
				SaveLoadManager.saves_info[i][0], 
				SaveLoadManager.saves_info[i][1]["day"], 
				SaveLoadManager.saves_info[i][1]["month"],
				SaveLoadManager.saves_info[i][1]["year"],
				SaveLoadManager.saves_info[i][1]["hour"],
				SaveLoadManager.saves_info[i][1]["minute"], 
				SaveLoadManager.saves_info[i][1]["second"]
				]
			saves_grid_container.get_child(i).text = "%s\n%d/%d/%d  %d:%d:%d" % save_info
		else:
			saves_grid_container.get_child(i).text = SaveLoadManager.saves_info[i][0]


# -- Creates scene where we get the save name --
func _go_save_title_menu() -> void:
	h_box_container.visible = false
	
	save_name_menu = save_name_scene.instantiate() as SaveTitleMenu
	call_deferred("add_child", save_name_menu)
	
	# Used for synchronization
	await get_tree().create_timer(0.1).timeout
	
	# Used to exit the new scene
	for child in get_children():
		if child.name == save_name_menu.name:
			child.save_title_menu_exit.connect(_return_from_save_title_menu)


func _return_from_save_title_menu() -> void:
	h_box_container.visible = true
	
	_save_slots_update()


# -- Controls elements of scene when in transition --
func action_buttons_state() -> void:
	if SaveLoadManager.saves_info[save_slot][0] == "VAZIO":
		actions_grid_container.get_child(0).disabled = false
		actions_grid_container.get_child(1).disabled = true
		actions_grid_container.get_child(2).disabled = true
	else:
		actions_grid_container.get_child(0).disabled = false
		actions_grid_container.get_child(1).disabled = false
		actions_grid_container.get_child(2).disabled = false
