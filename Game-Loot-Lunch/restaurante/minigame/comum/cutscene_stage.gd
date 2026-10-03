extends BossMinigame
class_name CutsceneStage
## BASE das CUTSCENES da boss fight (introdução do VIP, avaliação final...).
## É uma etapa como as outras (BossMinigame: `begin` / `finish`), mas sem controle do
## jogador, só com os movimentos de "câmera e atores" que toda cena animada usa:
##
##   await faixas_in()                              # faixas pretas de cinema
##   await walk(ator, destino, 1.2)                 # anda (toca "andar" se o ator tiver)
##   await zoom_to(posição, 2.0, 1.0)               # câmera
##   await talk(["VIP: Olá!", "Chef: Opa!"])        # diálogo (ESPAÇO avança)
##   say("VIP", "Hmm...")                           # fala sem esperar o jogador
##   hop(ator) / squash(ator) / face(ator, x) / arc(nó, de, até, altura, tempo) / fx(anim, pos)
##
## Quem herda escreve só o roteiro em `_on_begin()`.


@export var camera: Camera2D
@export var bars: CinemaBars
@export var dialogue: DialogueBox
## Atores cuja arte olha para a ESQUERDA (ex.: o chef jscoutinho_*_L).
@export var left_facing_actors: Array[Node2D] = []
## Atores que NUNCA viram (arte de frente, ex.: o VIP).
@export var fixed_facing_actors: Array[Node2D] = []
## Escala dos efeitos (cena com zoom: efeitos menores).
@export var fx_scale: float = 0.3
## Centro da tela sem zoom (para voltar a câmera).
@export var screen_center: Vector2 = Vector2(320, 180)


## Chave de quem fala ("VIP", "Chef"...) -> ator que "quica" quando a fala dele aparece.
## Preencha no `_ready` de quem herda: `speaker_actors = {"VIP": vip, "Chef": chef}`.
var speaker_actors: Dictionary = {}
## O jogador apertou ESC num diálogo: os próximos diálogos da cena também são pulados.
var dialogue_skipped: bool = false


func _ready() -> void:
	super._ready()
	if camera:
		camera.global_position = screen_center


func _on_begin() -> void:
	if camera:
		camera.make_current()


# --- Cinema ------------------------------------------------------------------------

func faixas_in(duration: float = 0.6) -> void:
	if bars:
		await bars.show_bars(duration)


func faixas_out(duration: float = 0.4) -> void:
	if bars:
		await bars.hide_bars(duration)


func zoom_to(target: Vector2, zoom: float, duration: float) -> void:
	if camera == null:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(camera, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", Vector2.ONE * zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func zoom_reset(duration: float = 0.9) -> void:
	await zoom_to(screen_center, 1.0, duration)


# --- Falas -------------------------------------------------------------------------

## Diálogo que espera o jogador (ESPAÇO avança, ESC pula). Lista vazia = não faz nada.
## Retorna false se o jogador pulou (ESC).
func talk(lines: Array) -> bool:
	if dialogue == null or lines.is_empty() or dialogue_skipped:
		return not dialogue_skipped
	if not dialogue.line_shown.is_connected(_on_line_shown):
		dialogue.line_shown.connect(_on_line_shown)
	dialogue_skipped = not await dialogue.play(lines)
	return not dialogue_skipped


func _on_line_shown(_index: int, speaker: String, _text: String) -> void:
	var actor: Node2D = speaker_actors.get(speaker, null)
	if actor and is_instance_valid(actor):
		face_toward_listener(speaker)
		squash(actor, Vector2(0.94, 1.08), 0.22)


## Quem fala olha para os outros atores da conversa (sobrescreva se quiser outra regra).
func face_toward_listener(speaker: String) -> void:
	var actor: Node2D = speaker_actors.get(speaker, null)
	for key in speaker_actors:
		var other: Node2D = speaker_actors[key]
		if other != actor and is_instance_valid(other):
			face(actor, other.global_position.x)
			return


## Fala sem esperar o jogador (para os momentos cronometrados). Texto vazio = fecha.
func say(speaker: String, text: String, color: Color = Color(0, 0, 0, 0)) -> void:
	if dialogue:
		dialogue.show_line(speaker, text, color)


# --- Atores ------------------------------------------------------------------------

## Anda até `to`. SheetSprite com animação "andar" toca a animação; sem ela, balança
## (`bob` px). `carry` vai junto (prato na cabeça), deslocado por `carry_offset`.
func walk(who: Node2D, to: Vector2, duration: float, bob: float = 0.0,
		carry: Node2D = null, carry_offset: Vector2 = Vector2.ZERO) -> void:
	var sheet := who as SheetSprite
	var has_walk: bool = sheet != null and sheet.has_sheet(&"andar")
	if has_walk:
		sheet.play_sheet(&"andar")
	face(who, to.x)
	var from: Vector2 = who.global_position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var hop_y: float = -absf(sin(t * duration * 9.0)) * bob
		who.global_position = from.lerp(to, t) + Vector2(0, hop_y)
		if carry:
			carry.global_position = who.global_position + carry_offset \
				+ Vector2(0, -absf(sin(t * 18.0)) * 1.5), 0.0, 1.0, duration)
	await tween.finished
	who.global_position = to
	if has_walk:
		sheet.play_sheet(&"idle")


## Vira o ator para olhar para `x`.
func face(who: Node2D, x: float) -> void:
	var sprite := who as AnimatedSprite2D
	if sprite == null or fixed_facing_actors.has(who) or is_equal_approx(x, who.global_position.x):
		return
	var looking_left: bool = x < who.global_position.x
	sprite.flip_h = looking_left != left_facing_actors.has(who)
	if sprite is SheetSprite:
		(sprite as SheetSprite).refresh_offset()


func squash(who: Node2D, amount: Vector2 = Vector2(1.1, 0.88), duration: float = 0.25) -> void:
	# Guarda a escala original na 1ª vez: dois "squash" seguidos não deformam o ator.
	if not who.has_meta(&"cutscene_base_scale"):
		who.set_meta(&"cutscene_base_scale", who.scale)
	var base: Vector2 = who.get_meta(&"cutscene_base_scale")
	var tween := create_tween()
	tween.tween_property(who, "scale", base * amount, duration * 0.5)
	tween.tween_property(who, "scale", base, duration * 0.5).set_trans(Tween.TRANS_BACK)
	await tween.finished


func hop(who: Node2D, height: float = 6.0, duration: float = 0.25) -> void:
	var base_y: float = who.position.y
	var tween := create_tween()
	tween.tween_property(who, "position:y", base_y - height, duration * 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(who, "position:y", base_y, duration * 0.5).set_ease(Tween.EASE_IN)
	await tween.finished


func shake(who: Node2D, amount: float = 3.0, times: int = 8) -> void:
	var base_x: float = who.position.x
	var tween := create_tween()
	for i in times:
		tween.tween_property(who, "position:x", base_x + (amount if i % 2 == 0 else -amount), 0.05)
	tween.tween_property(who, "position:x", base_x, 0.05)
	await tween.finished


## Leva `node` de `from` até `to` num arco (prato pousando, garfada subindo...).
func arc(node: Node2D, from: Vector2, to: Vector2, height: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(node):
			node.global_position = from.lerp(to, t) + Vector2(0.0, -height * sin(PI * t)), 0.0, 1.0, duration)
	await tween.finished


## Efeito de uma vez só (SheetAnimation) na posição global `at`.
func fx(anim: SheetAnimation, at: Vector2) -> void:
	if anim:
		var sprite: AnimatedSprite2D = SheetAnimation.spawn_once(anim, self, at)
		if sprite:
			sprite.scale = anim.scale * fx_scale
			sprite.z_index = 60
