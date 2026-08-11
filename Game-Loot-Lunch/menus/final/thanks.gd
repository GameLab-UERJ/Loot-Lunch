extends Control
class_name ThanksScreen


@onready var typing_sfx: AudioStreamPlayer = $TypingSfx
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var hover_audio: AudioStreamPlayer = $HoverAudio


func _on_button_pressed() -> void:
	press_audio.play()
	await press_audio.finished
	EasyTransition.transition_to_path("uid://b2evbancyosmu",1.5,EasyTransition.TransitionAnim.FADE)


func _on_button_hovered() -> void:
	hover_audio.play()
