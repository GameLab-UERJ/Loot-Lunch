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
@export var dialogue: Node = null
@export var dialogue_resource: DialogueResource = preload("res://resources/dialogues/vip_boss.dialogue")
## Atores cuja arte olha para a ESQUERDA. O chef e o VIP (jscoutinho_*) olham para a
## DIREITA, apesar do "_L" no nome do arquivo (igual ao `sprite_faces_left = false` do chef.gd).
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

# --- Falas -------------------------------------------------------------------------

var _subtitle_layer: CanvasLayer
var _subtitle_label: Label
var _subtitle_panel: PanelContainer


## Diálogo que espera o jogador (ESPAÇO avança, ESC pula) usando DialogueManager 3.
## Aceita o título da fala (ex: "intro_meeting") ou array de falas por compatibilidade.
func talk(dialogue_input, custom_resource: DialogueResource = null) -> bool:
	if dialogue_skipped:
		return false
	
	var resource: DialogueResource = custom_resource if custom_resource else dialogue_resource
	var dialogue_title: String = ""
	
	if dialogue_input is String:
		dialogue_title = dialogue_input
	elif dialogue_input is Array:
		dialogue_title = _resolve_dialogue_title(dialogue_input)
	
	if dialogue_title.is_empty() or resource == null:
		return not dialogue_skipped

	var callback := func(line: DialogueLine) -> void:
		if line and not line.character.is_empty():
			_on_line_shown(0, line.character, line.text)

	if not Engine.is_editor_hint():
		DialogueManager.got_dialogue.connect(callback)
		var balloon: Node = DialogueManager.show_dialogue_balloon(resource, dialogue_title)
		if balloon:
			await DialogueManager.dialogue_ended
		if DialogueManager.got_dialogue.is_connected(callback):
			DialogueManager.got_dialogue.disconnect(callback)

	return not dialogue_skipped


func _resolve_dialogue_title(lines: Array) -> String:
	if lines.is_empty():
		return ""
	var first_line: String = String(lines[0])
	if first_line.begins_with("VIP: Com licença"):
		return "intro_meeting"
	elif first_line.begins_with("Chef: ...\"detalhe\""):
		return "intro_after_sit"
	elif first_line.begins_with("VIP: Chef... em trezentos"):
		return "outro_perfect"
	elif first_line.begins_with("VIP: Muito bem, chef"):
		return "outro_good"
	elif first_line.begins_with("VIP: Bom... pelo menos"):
		return "outro_medium"
	elif first_line.begins_with("VIP: Acho que vou continuar"):
		return "outro_bad"
	return ""


func _on_line_shown(_index: int, speaker: String, _text: String) -> void:
	# Normaliza nome para lookup de atores
	var key: String = speaker
	if speaker == "Coronel Ossvaldo":
		key = "VIP"
	var actor: Node2D = speaker_actors.get(key, speaker_actors.get(speaker, null))
	if actor and is_instance_valid(actor):
		face_toward_listener(key)
		squash(actor, Vector2(0.94, 1.08), 0.22)


## Quem fala olha para os outros atores da conversa (sobrescreva se quiser outra regra).
func face_toward_listener(speaker: String) -> void:
	var key: String = speaker
	if speaker == "Coronel Ossvaldo":
		key = "VIP"
	var actor: Node2D = speaker_actors.get(key, speaker_actors.get(speaker, null))
	for k in speaker_actors:
		var other: Node2D = speaker_actors[k]
		if other != actor and is_instance_valid(other):
			face(actor, other.global_position.x)
			return


## Fala rápida sem esperar o jogador (para momentos cronometrados). Texto vazio = fecha.
func say(speaker: String, text: String, color: Color = Color(0, 0, 0, 0)) -> void:
	if dialogue and dialogue.has_method("show_line"):
		dialogue.call("show_line", speaker, text, color)
		return
	_ensure_subtitle_ui()
	if text.strip_edges().is_empty():
		_subtitle_panel.hide()
		return
	_subtitle_panel.show()
	if speaker != "":
		_subtitle_label.text = "%s: %s" % [speaker, text]
	else:
		_subtitle_label.text = text
	if color.a > 0.0:
		_subtitle_label.add_theme_color_override("font_color", color)
	else:
		_subtitle_label.remove_theme_color_override("font_color")


func _ensure_subtitle_ui() -> void:
	if _subtitle_layer:
		return
	_subtitle_layer = CanvasLayer.new()
	_subtitle_layer.layer = 30
	add_child(_subtitle_layer)
	
	_subtitle_panel = PanelContainer.new()
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_subtitle_panel.anchor_top = 1.0
	_subtitle_panel.anchor_bottom = 1.0
	_subtitle_panel.offset_left = 60
	_subtitle_panel.offset_right = -60
	_subtitle_panel.offset_bottom = -24
	_subtitle_panel.offset_top = -64
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.6, 0.6, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	_subtitle_panel.add_theme_stylebox_override("panel", style)
	
	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_override("font", preload("res://assets/fonts/Silver.ttf"))
	_subtitle_label.add_theme_font_size_override("font_size", 22)
	_subtitle_panel.add_child(_subtitle_label)
	_subtitle_layer.add_child(_subtitle_panel)
	_subtitle_panel.hide()


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
