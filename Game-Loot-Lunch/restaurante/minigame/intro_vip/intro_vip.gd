extends CutsceneStage
class_name VipIntro
## INTRODUÇÃO da boss fight: o CLIENTE VIP chega no Ossos & Brasas.
##   1. salão vazio, o chef esperando; a porta abre ("tlim-tlim!") e o VIP entra;
##   2. a câmera aproxima e os dois conversam (`lines_meeting`, ESPAÇO avança, ESC pula):
##      ele é o Coronel Ossvaldo, fazendeiro do Primeiro Andar da Masmorra, cria
##      tanajuras gigantes e quer saber se dá para fazer um prato com elas;
##      o chef já tem a receita em mente;
##   3. o VIP vai sentar na mesa (o mesmo lugar onde ele prova o prato no final);
##   4. o chef fala a última (`lines_after_sit`) e vai para a cozinha -> começam as etapas.
##
## As falas ficam no Inspector (grupo "Falas"), no formato "Quem: fala". Nome, cor e
## retrato de cada um ficam em `comum/dialogo_vip.tscn`.


@export var vip: SheetSprite
@export var chef: SheetSprite
## Porta aberta (fica visível enquanto o VIP entra).
@export var door_open: CanvasItem
@export var vip_door_spot: Marker2D
@export var vip_talk_spot: Marker2D
@export var vip_seat: Marker2D
@export var chef_spot: Marker2D
@export var chef_exit: Marker2D
@export var talk_zoom: float = 1.6

@export_group("Falas")
@export var opening_line: String = "Ossos & Brasas. Hora do almoço..."
@export var doorbell_text: String = "Tlim-tlim!"
@export var lines_meeting: Array[String] = [
	"VIP: Com licença! É aqui o tal do Ossos & Brasas? O cheirinho desse churrasco chega até o Primeiro Andar da Masmorra!",
	"Chef: É aqui mesmo! Seja bem-vindo! Mesa pra um?",
	"VIP: Pra um, sim. Permita que eu me apresente: Coronel Ossvaldo, o maior fazendeiro do Primeiro Andar da Masmorra!",
	"Chef: Fazendeiro... dentro de uma masmorra? E planta o quê lá embaixo? Cogumelo?",
	"VIP: Cogumelo é coisa de amador! Eu crio FORMIGAS. Tanajuras gigantes, do tamanho de um bezerro!",
	"Chef: ...do tamanho de um bezerro.",
	"VIP: Ganharam até prêmio na feira dos goblins! Só tem um probleminha: são milhares. Elas comem a cerca. Comem o celeiro...",
	"VIP: Semana passada comeram o meu chapéu. Esse aqui é o reserva.",
	"VIP: Aí eu pensei: se não dá pra vencer elas... será que dá pra COMER elas? Dá pra fazer algum prato com isso, chef?",
	"Chef: Coronel... o senhor está falando com um cozinheiro que nasceu no Rio de Janeiro.",
	"VIP: Rio de quê?",
	"Chef: Deixa pra lá. O importante é que na minha terra a gente come tanajura com farofa! E eu já tenho uma receita em mente.",
	"Chef: Carne de sol, macaxeira na manteiga de garrafa e uma farofa de tanajura de respeito. O prato completo!",
	"VIP: Não entendi metade das palavras, mas gostei da confiança! Fechado!",
	"VIP: Ah, só um detalhe: eu trouxe umas formigas de amostra... e elas não estão muito felizes com a ideia.",
	"Chef: Como assim, \"não estão muito felizes\"?",
	"VIP: Detalhe, detalhe! Vou sentar ali e esperar. Capricha, hein? Meu paladar é exigente!",
]
@export var lines_after_sit: Array[String] = [
	"Chef: ...\"detalhe\", ele disse.",
	"Chef: Tudo bem. Avental no lugar, frigideira na mão. Mãos à obra!",
]


func _ready() -> void:
	super._ready()
	speaker_actors = {"VIP": vip, "Chef": chef}
	if door_open:
		door_open.hide()
	if vip and vip_door_spot:
		vip.global_position = vip_door_spot.global_position
		vip.modulate.a = 0.0
		face(vip, chef_spot.global_position.x)  # o VIP olha para o chef
	if chef and chef_spot:
		chef.global_position = chef_spot.global_position
		face(chef, chef.global_position.x + 100.0)


func _on_begin() -> void:
	super._on_begin()
	faixas_in()
	await wait(0.6)
	say("", opening_line)
	await wait(1.8)
	say("", "")

	# 1. A porta abre e o VIP entra.
	await _enter()

	# 2. Conversa.
	var middle: Vector2 = (chef.global_position + vip.global_position) * 0.5 + Vector2(0, -5)
	await zoom_to(middle, talk_zoom, 0.9)
	await talk(lines_meeting)

	# 3. O VIP vai para a mesa (por trás dela) e senta.
	var behind_table := Vector2(vip_talk_spot.global_position.x - 22.0, vip_seat.global_position.y + 2.0)
	zoom_to((chef.global_position + vip_seat.global_position) * 0.5 + Vector2(0, 8), talk_zoom * 0.85, 1.4)
	await walk(vip, behind_table, 0.6, 2.0)
	await walk(vip, vip_seat.global_position + Vector2(0, -2), 0.6, 2.0)
	await hop(vip, 4.0, 0.2)
	vip.global_position = vip_seat.global_position
	await squash(vip, Vector2(1.12, 0.88), 0.25)
	face(chef, vip.global_position.x)
	face(vip, chef.global_position.x)
	await wait(0.4)

	# 4. O chef fala a última e vai para a cozinha.
	await talk(lines_after_sit)
	zoom_reset(1.0)
	await walk(chef, chef_exit.global_position, 1.2)
	await faixas_out()
	finish(true, {"label": "Introdução: o Coronel Ossvaldo chegou"})


func _enter() -> void:
	if door_open:
		door_open.show()
	popup(vip_door_spot.global_position + Vector2(0, -44), doorbell_text, Color(1.0, 0.9, 0.5))
	await wait(0.35)
	var appear := create_tween()
	appear.tween_property(vip, "modulate:a", 1.0, 0.3)
	await appear.finished
	await walk(vip, vip_door_spot.global_position + Vector2(0, 8), 0.3, 2.0)
	if door_open:
		door_open.hide()
	face(chef, vip_talk_spot.global_position.x)
	await walk(vip, vip_talk_spot.global_position, 0.8, 2.0)
	await wait(0.3)
