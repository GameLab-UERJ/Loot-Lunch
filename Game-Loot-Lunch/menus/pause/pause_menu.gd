extends CanvasLayer
class_name PauseMenu

var save_load_menu: SaveLoadMenu
# Preload SaveLoadMenu
var save_load_scene: PackedScene = preload("uid://dr6jrbiw3vgd3")
var settings_scene: PackedScene = preload("res://menus/settings/settings_menu.tscn")


@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var panel: Panel = $Panel

func _ready() -> void:
	visible = false
	
	QuestManager.mission_updated.connect(_update_text_mission)
	
	_update_text_mission(QuestManager.current_status)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if visible:
			if panel.visible:
				resume()
		else:
			pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if not visible and not get_tree().paused:
			pause()


func _on_return_buttom_pressed() -> void:
	resume()
	_on_button_mouse_pressed()


func _on_save_load_button_pressed() -> void:
	panel.visible = false
	
	save_load_menu = save_load_scene.instantiate() as SaveLoadMenu
	call_deferred("add_child", save_load_menu)
	
	# Used for synchronization
	await get_tree().create_timer(0.1).timeout
	
	# Used to exit the new scene
	for child in get_children():
		if child.name == save_load_menu.name:
			child.save_load_menu_exit.connect(_return_from_menus)
	
	_on_button_mouse_pressed()


func _on_settings_button_pressed() -> void:
	_on_button_mouse_pressed()
	panel.visible = false
	var settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	await settings_instance.tree_exited
	panel.visible = true
	#print("settings")
	await _on_button_mouse_pressed()


# To get uid
# print(ResourceUID.id_to_text(ResourceLoader.get_resource_uid(PATH)))
func _on_main_menu_button_pressed() -> void:
	var in_restaurant: bool = _is_in_restaurant()
	resume()
	
	await _on_button_mouse_pressed()
	if in_restaurant:
		MvpFlow.exit_restaurant(get_tree())
		close()
	else:
		# Goes to MainMenu
		EasyTransition.transition_to_path("uid://b2evbancyosmu", 1.0, EasyTransition.TransitionAnim.BLUR)
		close()


func close() -> void:
	visible = false
	get_tree().paused = false
	queue_free()


func _on_quit_button_pressed() -> void:
	visible = false
	
	await _on_button_mouse_pressed()
	get_tree().quit()


# -- Effect when mouse enters any element --
func _on_buttom_mouse_entered() -> void:
	if hover_audio == null:
		return
		
	hover_audio.play()
	await hover_audio.finished


# -- Effect when mouse clicks any element --
func _on_button_mouse_pressed() -> void:
	if press_audio == null:
		return
	
	press_audio.play()
	await get_tree().create_timer(0.35).timeout


func pause() -> void:
	visible = true
	get_tree().paused = true
	var in_restaurant: bool = _is_in_restaurant()
	var main_menu_btn: Button = $Panel/VBoxContainer/ActinonsGridContainer/MainMenuButton
	var save_load_btn: Button = $Panel/VBoxContainer/ActinonsGridContainer/SaveLoadButton
	var mission_label: Label = $Panel/MissionLabel
	if main_menu_btn:
		main_menu_btn.text = "Sair do restaurante" if in_restaurant else "Main Menu"
	if save_load_btn:
		save_load_btn.visible = not in_restaurant
	if mission_label:
		mission_label.visible = not in_restaurant
	var return_btn: Button = $Panel/VBoxContainer/ActinonsGridContainer/ReturnButtom
	if return_btn:
		return_btn.grab_focus()


func resume() -> void:
	visible = false
	get_tree().paused = false


func _is_in_restaurant() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return scene is RestaurantLevel or scene.name == "BossFightVip" or scene.scene_file_path.begins_with("res://levels/restaurant/") or scene.scene_file_path.begins_with("res://levels/minigames/")


func _return_from_menus() -> void:
	panel.visible = true

func _update_text_mission(new_stage: int) -> void:
	$Panel/MissionLabel.text = QuestManager.get_mission_text(new_stage)
