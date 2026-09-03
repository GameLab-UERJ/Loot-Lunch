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


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused == false:
			pause()
		else:
			resume()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
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
	resume()
	
	await _on_button_mouse_pressed()
	# Goes to MainMenu
	EasyTransition.transition_to_path("uid://b2evbancyosmu",1.0,EasyTransition.TransitionAnim.BLUR)
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


func resume() -> void:
	visible = false
	get_tree().paused = false


func _return_from_menus() -> void:
	panel.visible = true

func _update_text_mission(new_stage: int) -> void:
	$Panel/MissionLabel.text = QuestManager.get_mission_text(new_stage)
