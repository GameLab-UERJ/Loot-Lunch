extends Control
class_name MvpThanks
## TELA DE AGRADECIMENTO do MVP: aparece depois que o jogador vence a boss fight do
## Cliente VIP. Os textos entram um de cada vez e o botão leva de volta ao menu principal.


@export var hover_sound: AudioStream
@export var press_sound: AudioStream
## Segundos entre um texto e o próximo.
@export var step_time: float = 0.6


@onready var parts: Array[CanvasItem] = [%Logo, %Titulo, %Obrigado, %Autores, %Equipe]
@onready var back_button: Button = %VoltarMenu
@onready var music: AudioStreamPlayer = $Musica
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio


var _leaving: bool = false


func _ready() -> void:
	get_tree().paused = false
	DayNightSwitch.disable(self)
	hover_audio.stream = hover_sound
	press_audio.stream = press_sound
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_back_hovered)
	back_button.disabled = true
	back_button.modulate.a = 0.0
	for part in parts:
		part.modulate.a = 0.0
	if music.stream:
		music.volume_db = -40.0
		music.play()
		create_tween().tween_property(music, "volume_db", -12.0, 2.0)
	_reveal()


func _reveal() -> void:
	await get_tree().create_timer(0.4).timeout
	for part in parts:
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(part, "modulate:a", 1.0, 0.8)
		await get_tree().create_timer(step_time).timeout
	await get_tree().create_timer(0.6).timeout
	await create_tween().tween_property(back_button, "modulate:a", 1.0, 0.5).finished
	back_button.disabled = false
	back_button.grab_focus()


func _on_back_hovered() -> void:
	if hover_audio.stream and not back_button.disabled:
		hover_audio.play()


func _on_back_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	back_button.disabled = true
	if press_audio.stream:
		press_audio.play()
	if music.playing:
		create_tween().tween_property(music, "volume_db", -60.0, 0.8)
	MvpFlow.go_to_main_menu(get_tree())
