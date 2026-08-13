extends Control
class_name ThanksScreen


@export var is_outdoor: bool = false


@onready var typing_sfx: AudioStreamPlayer = $TypingSfx
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var logo: TextureRect = $CanvasLayer/Logo
@onready var thanks_label: Label = $VBoxContainer/ThanksLabel
@onready var button: Button = $VBoxContainer/Button
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var timer: Timer = $Timer


func _ready() -> void:
	if get_tree().root.has_node("PauseMenu"):
		get_tree().root.get_node("PauseMenu").queue_free()
	music_player.play(42)
	create_tween().tween_property(music_player,"volume_db",-12,3)
	await get_tree().create_timer(0.5).timeout
	await _animate_logo()
	await _animate_thanks()
	button.mouse_filter = Control.MOUSE_FILTER_PASS


func _animate_logo() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(logo,"modulate",Color.WHITE,2)
	tween.tween_property(logo,"size",Vector2(320,180),2)
	tween.parallel().tween_property(logo,"position",Vector2(160,240),2)
	await tween.finished


func _animate_thanks() -> void:
	await create_tween().tween_property(thanks_label,"visible_ratio",1,3).finished
	await get_tree().create_timer(2).timeout
	await create_tween().tween_property(button,"modulate",Color.WHITE,2).finished


func _on_button_pressed() -> void:
	button.disabled = true
	press_audio.play()
	await press_audio.finished
	go_to_main_menu()


func _on_button_hovered() -> void:
	hover_audio.play()


func _on_music_player_finished() -> void:
	go_to_main_menu()


func go_to_main_menu() -> void:
	create_tween().tween_property(music_player,"volume_db",-80,1.5)
	EasyTransition.transition_to_path("uid://b2evbancyosmu",1.5,EasyTransition.TransitionAnim.FADE)
