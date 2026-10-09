@tool
extends Node2D
class_name TutorialPage
## UMA PÁGINA de um quadro de tutorial (TutorialBoard). Os filhos são o DESENHO:
## sprites do jogo com o material de giz (chalk_material.tres), setas e rabiscos
## (ChalkDoodle), teclas (KeyCap) e textos curtos (Label com a fonte Silver).
##
## Coordenadas = pixels da tela (640x360). A área livre para desenhar fica mais ou menos
## entre y = 56 e y = 290 (em cima vai o título; embaixo, a legenda e o rodapé).
##
## Página nova = duplique uma página pronta (Ctrl+D) dentro do quadro e troque o desenho.


## Título grande no alto do quadro (a fonte do título não tem acento: evite acentos).
@export var title: String = "NOVA RECEITA"
## Legenda embaixo do desenho. Aceita BBCode: [color=#7CFC7C]verde[/color], [b]...[/b].
@export_multiline var caption: String = ""
## Texto da etiqueta de papel no canto (vazio = usa o do quadro).
@export var tag_text: String = ""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
