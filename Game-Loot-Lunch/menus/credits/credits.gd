extends Control
class_name Credits


@export_range (0, 10000, 01) var margin_increment: float = 0

var text_box_size: float
var window_size: float
var tween: Tween
var scroll_amount: float
var credits_time: float

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var margin: MarginContainer = $ScrollContainer/MarginContainer
@onready var rich_text_label: RichTextLabel = $ScrollContainer/MarginContainer/RichTextLabel
@onready var credits_db: CredidsDB = $CreditsDB
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	EnvironmentManager.is_outdoor = false
	
	text_box_size = rich_text_label.size.y
	window_size = DisplayServer.window_get_size().y
	# tela inicial vazia
	margin.add_theme_constant_override('margin_top', window_size + margin_increment)
	# tela final vazia
	margin.add_theme_constant_override('margin_bottom', window_size + margin_increment)
	
	credit_text()
	auto_scroll()
	audio_stream_player_2d.play()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_credit_finished()


func credit_text() -> void:
	rich_text_label.text += '[center]'
	rich_text_label.text += '[br][font_size={48}][b]' + '\n\nCreditos\n' + '[/b][/font_size]'
	
	for i in credits_db.categories:
		rich_text_label.text += '[br][font_size={24}][b]' + '\n\n' + credits_db.categories[i] + '\n' + '[/b][/font_size]'
	
		for j in credits_db.equip_credits:
			if i in credits_db.equip_credits[j]['role']:
				rich_text_label.text += '[br]' + j
	
	rich_text_label.text += '[/center]'


func auto_scroll() -> void:
	tween = create_tween()
	scroll_amount = ceil(text_box_size + 3/4 + window_size * 2 + margin_increment)
	credits_time = audio_stream_player_2d.stream.get_length() / 20
	
	tween.tween_property(
		scroll_container,
		'scroll_vertical',
		scroll_amount,
		credits_time
	)
	
	tween.play()
	tween.finished.connect(_credit_finished)


func _credit_finished() -> void:
	EasyTransition.transition_to_path("uid://b2evbancyosmu",1.0,EasyTransition.TransitionAnim.FADE)
