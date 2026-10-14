extends Control
class_name MvpCredits
## PAINEL DE CRÉDITOS do MVP, aberto por cima do menu principal (sem trocar de cena).
## Estático: só mostra quem fez a demonstração, a disciplina e a equipe do GameLab.
##
## A lista da equipe vem do CredidsDB (menus/credits/credits_db.gd), o mesmo banco dos
## créditos do jogo principal: entrou gente nova no GameLab, é só atualizar lá.
## `extra_members` soma nomes que ainda não estão no banco.
##
## Fecha com o botão "Voltar" ou ESC e avisa por `closed`.


signal closed


@export_group("Textos")
@export var title_text: String = "Créditos"
@export var subtitle_text: String = "Loot & Lunch — Demonstração"
@export var developers_title: String = "Desenvolvido por"
@export var developers: String = "Igor Amaral, Ramon Lima e João Coutinho"
@export_multiline var discipline_text: String = "Esta demonstração foi feita para a disciplina\nEngenharia de Sistema A, do professor Gabriel Carvalho."
@export var team_title: String = "Equipe GameLab-UERJ"
## Nomes que entram na lista da equipe além dos do CredidsDB.
@export var extra_members: PackedStringArray = ["João Coutinho"]
## Colunas da lista da equipe.
@export_range(1, 5) var team_columns: int = 3

@export_group("Audio")
@export var hover_sound: AudioStream = preload("res://assets/sfx/menus/abs-pointer-2.mp3")
@export var press_sound: AudioStream = preload("res://assets/sfx/menus/abs-confirm-2.mp3")


@onready var title_label: Label = %Titulo
@onready var subtitle_label: Label = %Subtitulo
@onready var developers_title_label: Label = %DevsTitulo
@onready var developers_label: Label = %Devs
@onready var discipline_label: Label = %Disciplina
@onready var team_title_label: Label = %EquipeTitulo
@onready var team_grid: GridContainer = %Equipe
@onready var back_button: Button = %Voltar
@onready var member_template: Label = %NomeModelo
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio


func _ready() -> void:
	title_label.text = title_text
	subtitle_label.text = subtitle_text
	developers_title_label.text = developers_title
	developers_label.text = developers
	discipline_label.text = discipline_text
	team_title_label.text = team_title
	team_grid.columns = team_columns
	member_template.hide()
	_fill_team()
	if hover_audio:
		hover_audio.stream = hover_sound
	if press_audio:
		press_audio.stream = press_sound
	back_button.mouse_entered.connect(_on_back_button_hovered)
	back_button.pressed.connect(_on_back_button_pressed)


func _on_back_button_hovered() -> void:
	if hover_audio and hover_audio.stream and not back_button.disabled:
		hover_audio.play()


func _on_back_button_pressed() -> void:
	if press_audio and press_audio.stream:
		press_audio.play()
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## Todos que estão no GameLab hoje (CredidsDB + extras), sem repetir.
static func team_members(extra: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	var names := PackedStringArray()
	for member in CredidsDB.equip_credits:
		names.append(String(member))
	for member in extra:
		if not names.has(member):
			names.append(member)
	return names


func _fill_team() -> void:
	for child in team_grid.get_children():
		if child != member_template:
			child.queue_free()
	for member in team_members(extra_members):
		var label := member_template.duplicate() as Label
		label.text = member
		label.show()
		team_grid.add_child(label)
