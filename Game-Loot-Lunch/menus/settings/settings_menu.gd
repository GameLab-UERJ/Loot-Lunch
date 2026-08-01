extends CanvasLayer

@onready var fullscreen_check: CheckBox = $"TextureRect/GridContainer2/FullScreenCheckBox"
@onready var audio_slider: HSlider = $"TextureRect/GridContainer/AudioSlider"
@onready var back_button: Button = $"TextureRect/GridContainer3/Button"
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio

func _ready() -> void:
	var current_mode = DisplayServer.window_get_mode()
	var is_fullscreen = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	fullscreen_check.set_pressed_no_signal(is_fullscreen)
	
	var master_bus_idx = AudioServer.get_bus_index("Master")
	var current_vol_db = AudioServer.get_bus_volume_db(master_bus_idx)
	
	audio_slider.set_value_no_signal(db_to_linear(current_vol_db))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	audio_slider.value_changed.connect(_on_audio_slider_value_changed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	back_button.mouse_entered.connect(_play_hover_sound)
	fullscreen_check.mouse_entered.connect(_play_hover_sound)
	audio_slider.mouse_entered.connect(_play_hover_sound)

func _play_hover_sound() -> void:
	if hover_audio and hover_audio.stream:
		hover_audio.play()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if press_audio and press_audio.stream:
		press_audio.play()
		
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_audio_slider_value_changed(value: float) -> void:
	var master_bus_idx = AudioServer.get_bus_index("Master")
	
	if value <= 0.0001:
		AudioServer.set_bus_mute(master_bus_idx, true)
	else:
		AudioServer.set_bus_mute(master_bus_idx, false)
		AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func _on_back_button_pressed() -> void:
	if press_audio and press_audio.stream:
		press_audio.play()
		await press_audio.finished
		
	var parent = get_parent()
	if parent and "content" in parent:
		parent.content.visible = true

	queue_free()
