extends Control

class_name SaveTitleMenu

signal save_title_menu_exit()

var chars: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
var new_name: String = ""

var old_caret_position: int
var regex: RegEx 
var diff: int

@onready var line_edit: LineEdit = $Panel/HBoxContainer/VBoxContainer/GridContainer/LineEdit
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var fail_audio: AudioStreamPlayer = $FailAudio


func _ready() -> void:
	line_edit.grab_focus()
	
	if SaveLoadManager.saves_info[get_parent().save_slot][0] != "VAZIO":
		line_edit.text = SaveLoadManager.saves_info[get_parent().save_slot][0]
		line_edit.caret_column = line_edit.text.length()


func _on_confirm_button_pressed() -> void:
	if line_edit.text == "":
		random_name()
	elif !new_name_check():
		line_edit.placeholder_text = "Invalid name"
		line_edit.clear()
		
		fail_audio.play()
		return
	
	SaveLoadManager.save_data(get_parent().save_slot, new_name)
	
	emit_signal("save_title_menu_exit")
	get_parent().action_buttons_state()
	
	_on_mouse_pressed()


func _on_canceld_button_pressed() -> void:
	_on_mouse_pressed()
	
	emit_signal("save_title_menu_exit")


# -- Effect when mouse clicks any buttons --
func _on_mouse_pressed() -> void:
	if press_audio == null:
		return
		
	visible = false
	
	press_audio.play()
	await press_audio.finished
	
	queue_free()


# -- Effect when mouse enters any element --
func _on_mouse_entered() -> void:
	if hover_audio == null:
		return
		
	hover_audio.play()
	await hover_audio.finished


# --- Creates random save name ---
func random_name() -> void:
	for i in range(12):
		new_name += chars[randi() % chars.length()]


# --- Blocks undesirable characters used in new save name ---
func _on_line_edit_text_changed(new_text: String) -> void:
	old_caret_position = line_edit.caret_column
	new_name = ""
	
	regex = RegEx.new()
	regex.compile("[A-Za-z0-9 ]")
	
	diff = regex.search_all(new_text).size() - new_text.length()
	
	for valid_caret in regex.search_all(new_text):
		new_name += valid_caret.get_string()
		
	line_edit.text = new_name
	line_edit.caret_column = old_caret_position + diff


# -- Checks if new name is valid --
func new_name_check() -> bool:
	new_name = line_edit.text
	
	if SaveLoadManager.saves_info[get_parent().save_slot][0] == new_name:
		return true
	
	for save in SaveLoadManager.saves_info:
		if save[0] == new_name:
			return false
			
	return true
