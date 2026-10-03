extends CutsceneStage
class_name VipTasting
## FINAL da boss fight: A AVALIAÇÃO DO CLIENTE VIP (estilo Dave the Diver / o crítico
## do Ratatouille). Cena animada, sem controle do jogador:
##   1. o VIP espera sentado na mesa, sob a luz;
##   2. o chef entra com o prato, serve e se afasta;
##   3. a câmera dá ZOOM no VIP, ele prova a garfada, mastiga... suspense...
##   4. REAÇÃO conforme as estrelas das 3 etapas (`rate()`):
##        PERFEITO -> 3 estrelas em todas
##        BOM      -> nenhuma abaixo de 2 e pelo menos uma com 3
##        MÉDIO    -> 2 estrelas em todas
##        RUIM     -> alguma abaixo de 2
##   5. câmera abre e os dois conversam (`outro_*`). Em BOM e PERFEITO o Coronel convida
##      o chef para negociar na fazenda dele (resultado traz "farm_deal" = true).
##
## O BossFightVip entrega as estrelas por `set_results(resultados)` antes do `begin()`.
## Rodando sozinha (F6) usa `preview_stars` (troque no Inspector para ver cada reação).
## Os movimentos (andar, zoom, falas...) vêm da base CutsceneStage.


enum Reaction { RUIM, MEDIO, BOM, PERFEITO }

const REACTION_NAMES: Array[String] = ["RUIM", "MÉDIO", "BOM", "PERFEITO"]
const REACTION_COLORS: Array[Color] = [Color(1.0, 0.45, 0.4), Color(0.85, 0.85, 0.75),
	Color(0.55, 1.0, 0.55), Color(1.0, 0.85, 0.3)]


@export var vip: SheetSprite
@export var chef: SheetSprite
@export var dish: Sprite2D
@export var fork: Sprite2D
@export var rays: GoldenRays
## Escurece o fundo no zoom (CanvasItem, começa transparente).
@export var dim: CanvasItem
@export var chef_start: Marker2D
@export var chef_serve_spot: Marker2D
@export var chef_wait_spot: Marker2D
@export var dish_spot: Marker2D
## Estrelas usadas quando a cena roda sozinha (F6).
@export var preview_stars: Array[int] = [3, 3, 3]
@export var zoom_level: float = 2.4
## Para onde a câmera olha no zoom (em relação ao VIP).
@export var zoom_focus: Vector2 = Vector2(0, 4)

@export_group("Efeitos")
@export var hearts_fx: SheetAnimation
@export var sparkle_fx: SheetAnimation
@export var smoke_fx: SheetAnimation

@export_group("Falas")
## Falas cronometradas do VIP (sem esperar o jogador).
@export var intro_line: String = "Vejamos se este lugar merece a minha visita..."
@export var lines_perfect: Array[String] = ["...", "Isso... isso me lembra a comida da minha avó, lá na fazenda...", "MAGNÍFICO! PERFEITO!"]
@export var lines_good: Array[String] = ["Hmm!", "Muito bom! Muito bom mesmo!"]
@export var lines_medium: Array[String] = ["Hm.", "Aceitável... nada de mais."]
@export var lines_bad: Array[String] = ["...!", "Argh! Isto é... comida?!"]
## Conversa depois da reação ("Quem: fala", ESPAÇO avança). Lista vazia = sem conversa.
@export var outro_perfect: Array[String] = [
	"VIP: Chef... em trezentos anos de masmorra, nunca comi nada assim. E olha que eu já comi um dragão. Pequeno, mas era dragão.",
	"Chef: Obrigado, Coronel! O segredo é a manteiga de garrafa. E um pouquinho de saudade de casa.",
	"VIP: Escuta aqui: passa lá na minha fazenda, no Primeiro Andar da Masmorra. Formiga é o que não falta...",
	"VIP: ...e pra você eu faço preço de amigo. Um ÓTIMO negócio! Pode trazer a frigideira.",
	"Chef: Fechado! Só avisa às formigas que eu vou com fome.",
	"VIP: HAHAHA! Elas vão adorar a notícia. Quer dizer... não vão, não.",
]
@export var outro_good: Array[String] = [
	"VIP: Muito bem, chef! Não é a comida da minha avó... mas passou bem perto.",
	"VIP: Olha, se quiser, passa lá na minha fazenda no Primeiro Andar da Masmorra. A gente faz um ótimo negócio com essas formigas!",
	"Chef: Pode deixar, Coronel! Vou levar a frigideira.",
	"VIP: Leva duas. Elas mordem.",
]
@export var outro_medium: Array[String] = [
	"VIP: Bom... pelo menos agora essas formigas servem pra alguma coisa além de comer a minha cerca.",
	"Chef: Na próxima eu capricho mais, Coronel!",
]
@export var outro_bad: Array[String] = [
	"VIP: Acho que vou continuar só criando elas mesmo...",
	"Chef: ...a farofa estava meio crocante demais, né?",
	"VIP: A farofa MORDEU a minha língua, chef.",
]
## Linha extra no placar final quando o Coronel oferece o negócio (BOM/PERFEITO).
@export var deal_label: String = "Novo contato: Fazenda do Coronel (1º andar da masmorra)"


var stars: Array[int] = []
var reaction: int = Reaction.MEDIO
var _vip_rest: Vector2


## Estrelas de cada etapa (o BossFightVip chama antes do `begin`).
func set_results(results: Array) -> void:
	stars.clear()
	for r in results:
		if r is Dictionary:
			stars.append(int(r.get("stars", 0)))


## A regra das quatro reações (estática: o placar pode perguntar antes da cena).
static func rate(all_stars: Array[int]) -> int:
	if all_stars.is_empty():
		return Reaction.MEDIO
	var lowest: int = all_stars.min()
	var highest: int = all_stars.max()
	if lowest < 2:
		return Reaction.RUIM
	if lowest >= 3:
		return Reaction.PERFEITO
	if highest >= 3:
		return Reaction.BOM
	return Reaction.MEDIO


## BOM ou PERFEITO: o Coronel oferece negócio na fazenda.
static func offers_deal(value: int) -> bool:
	return value >= Reaction.BOM


func _ready() -> void:
	super._ready()
	if dish:
		dish.hide()
	if fork:
		fork.hide()
	if dim:
		dim.modulate.a = 0.0
	if vip:
		_vip_rest = vip.position
	if chef and chef_start:
		chef.global_position = chef_start.global_position


func _on_begin() -> void:
	super._on_begin()
	if stars.is_empty():
		stars = preview_stars.duplicate()
	reaction = rate(stars)
	faixas_in()

	# 1. O VIP espera.
	await wait(0.8)
	say("VIP", intro_line)
	await wait(2.2)

	# 2. O chef serve.
	await _serve()

	# 3. Zoom + garfada.
	await _zoom_in()
	await _taste()

	# 4. Reação.
	match reaction:
		Reaction.PERFEITO:
			await _react_perfect()
		Reaction.BOM:
			await _react_good()
		Reaction.MEDIO:
			await _react_medium()
		_:
			await _react_bad()
	await wait(0.8)
	say("", "")

	# 5. Câmera abre nos dois e eles conversam.
	_chef_reacts()
	var both: Vector2 = (vip.global_position + chef.global_position) * 0.5 + Vector2(0, 14)
	var open := create_tween().set_parallel(true)
	if dim:
		open.tween_property(dim, "modulate:a", 0.0, 0.9)
	await zoom_to(both, 1.6, 0.9)
	await talk(_outro_lines())
	await zoom_reset(0.8)
	await faixas_out()

	var quality: float = 0.0
	for s in stars:
		quality += s / 3.0
	quality /= maxf(stars.size(), 1)
	var deal: bool = offers_deal(reaction)
	var label: String = "Avaliação do VIP: %s" % REACTION_NAMES[reaction]
	if deal and deal_label != "":
		label += "\n" + deal_label
	finish(true, {
		"label": label,
		"title": REACTION_NAMES[reaction] + "!",
		"reaction": reaction,
		"reaction_name": REACTION_NAMES[reaction],
		"color": REACTION_COLORS[reaction],
		"farm_deal": deal,
		"quality": quality,
		"stars": BossMinigame.stars_for(quality),
	})


func _outro_lines() -> Array[String]:
	match reaction:
		Reaction.PERFEITO:
			return outro_perfect
		Reaction.BOM:
			return outro_good
		Reaction.MEDIO:
			return outro_medium
	return outro_bad


# --- Etapas da cena --------------------------------------------------------------

func _serve() -> void:
	if chef == null:
		return
	var plate_on_head := Vector2(0, -36)
	dish.show()
	dish.z_index = 6  # na frente do chef enquanto ele carrega
	dish.global_position = chef.global_position + plate_on_head
	await walk(chef, chef_serve_spot.global_position, 1.4, 0.0, dish, plate_on_head)
	# Põe o prato na mesa.
	await arc(dish, dish.global_position, dish_spot.global_position, 18.0, 0.45)
	dish.z_index = 3
	say("Chef", "Bon appétit!")
	await wait(0.9)
	await walk(chef, chef_wait_spot.global_position, 0.7)
	face(chef, vip.global_position.x)
	await squash(chef, Vector2(1.1, 0.85), 0.3)  # reverência
	await wait(0.4)


func _zoom_in() -> void:
	if dim:
		create_tween().tween_property(dim, "modulate:a", 0.55, 1.2)
	await zoom_to(vip.global_position + zoom_focus, zoom_level, 1.2)


func _taste() -> void:
	# A garfada sobe do prato até a boca.
	if fork:
		fork.show()
		await arc(fork, dish.global_position + Vector2(6, -2), vip.global_position + Vector2(4, 4), 14.0, 0.7)
		fork.hide()
	for i in 3:
		await squash(vip, Vector2(1.08, 0.9), 0.22)
	await wait(0.3)
	say("VIP", "...")
	if camera:
		var push := create_tween()
		push.tween_property(camera, "zoom", Vector2.ONE * (zoom_level + 0.4), 1.2).set_trans(Tween.TRANS_SINE)
		await push.finished
	await wait(0.3)


# --- Reações -----------------------------------------------------------------------

func _react_perfect() -> void:
	say("VIP", lines_perfect[0])
	await wait(0.8)
	if dim:
		create_tween().tween_property(dim, "modulate:a", 0.85, 0.6)
	if rays:
		rays.global_position = vip.global_position + Vector2(0, -4)
		rays.burst(0.6)
	if lines_perfect.size() > 1:
		say("VIP", lines_perfect[1], Color(1.0, 0.9, 0.6))
	var lift := create_tween()
	lift.tween_property(vip, "position:y", _vip_rest.y - 3.0, 1.2).set_trans(Tween.TRANS_SINE)
	await wait(2.6)
	if bars:
		await bars.flash(0.9)
	for i in 6:
		fx(sparkle_fx, vip.global_position + Vector2(randf_range(-22, 22), randf_range(-26, 6)))
		await wait(0.08)
	fx(hearts_fx, vip.global_position + Vector2(0, -8))
	say("VIP", lines_perfect.back(), REACTION_COLORS[Reaction.PERFEITO])
	_confetti(30)
	for i in 2:
		await hop(vip, 6.0, 0.25)
	await wait(1.6)
	create_tween().tween_property(vip, "position:y", _vip_rest.y, 0.4)
	if rays:
		rays.fade_out()


func _react_good() -> void:
	say("VIP", lines_good[0])
	await wait(0.7)
	fx(hearts_fx, vip.global_position + Vector2(0, -8))
	say("VIP", lines_good.back(), REACTION_COLORS[Reaction.BOM])
	for i in 2:
		await hop(vip, 5.0, 0.25)
	fx(sparkle_fx, vip.global_position + Vector2(-14, -12))
	fx(sparkle_fx, vip.global_position + Vector2(14, -12))
	await wait(1.6)


func _react_medium() -> void:
	say("VIP", lines_medium[0])
	await wait(0.9)
	await squash(vip, Vector2(1.0, 0.92), 0.3)  # aceno curto
	say("VIP", lines_medium.back(), REACTION_COLORS[Reaction.MEDIO])
	await wait(1.8)


func _react_bad() -> void:
	say("VIP", lines_bad[0])
	await wait(0.6)
	vip.self_modulate = Color(0.75, 1.15, 0.7)  # verde de nojo
	fx(smoke_fx, vip.global_position + Vector2(6, 2))
	await shake(vip, 3.0, 8)
	say("VIP", lines_bad.back(), REACTION_COLORS[Reaction.RUIM])
	# Empurra o prato.
	var push := create_tween()
	push.tween_property(dish, "global_position:x", dish.global_position.x + 26.0, 0.35).set_trans(Tween.TRANS_BACK)
	await wait(1.8)
	vip.self_modulate = Color.WHITE


## O chef, lá atrás, reage junto (vê-se quando a câmera abre).
func _chef_reacts() -> void:
	if chef == null:
		return
	await wait(0.4)
	match reaction:
		Reaction.PERFEITO, Reaction.BOM:
			for i in (3 if reaction == Reaction.PERFEITO else 2):
				await hop(chef, 8.0, 0.28)
		Reaction.MEDIO:
			await squash(chef, Vector2(1.0, 0.94), 0.3)
		_:
			var base: Vector2 = chef.scale
			var slump := create_tween()
			slump.tween_property(chef, "scale", base * Vector2(1.1, 0.85), 0.35)
			slump.tween_interval(0.8)
			slump.tween_property(chef, "scale", base, 0.3)


func _confetti(count: int) -> void:
	var colors: Array[Color] = [Color(1.0, 0.85, 0.3), Color(0.95, 0.4, 0.45), Color(0.55, 0.85, 1.0), Color(0.6, 1.0, 0.55)]
	var center: Vector2 = camera.global_position if camera else screen_center
	for i in count:
		var bit := ColorRect.new()
		bit.color = colors[i % colors.size()]
		bit.size = Vector2(1.5, 1.5)
		bit.z_index = 70
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bit)
		var from: Vector2 = center + Vector2(randf_range(-70, 70), -80.0 - randf() * 20.0)
		bit.global_position = from
		var tween := bit.create_tween()
		tween.tween_property(bit, "global_position", from + Vector2(randf_range(-15, 15), 160.0), randf_range(1.2, 2.2))
		tween.tween_callback(bit.queue_free)
