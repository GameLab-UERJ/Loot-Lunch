extends CustomerAbility
class_name QuackAbility
## PATOLINO — MAGIA 1: QUACK GIGANTE.
##
## Um pato enorme e meio transparente aparece NO MEIO DA TELA gritando QUACK, a tela
## treme, e no quadro em que o bico abre (`peak_frame`) o chef leva um susto e DERRUBA o
## item que estava segurando (cai no chão com um pulinho). Se estava carregando o Q, o
## espetinho cai no pé, como quando leva dano.
##
## Não dá dano. Atinge todos os chefs do grupo dentro de `radius` (0 = a tela toda).
## A animação da tela é o ScreenOverlayEffect (reutilizável).


signal items_dropped(count: int)


@export_group("Tela")
@export var overlay_sheet: Texture2D = preload("res://restaurante/clientes/patolino/habilidade_arte/patolino_quack_256_spritesheet.png")
@export var frame_size: Vector2i = Vector2i(256, 256)
@export var fps: float = 8.0
## 0 = invisível, 1 = opaco. 0.5 deixa ver o jogo por trás.
@export_range(0.0, 1.0) var opacity: float = 0.5
## Tamanho na tela (a tela do jogo tem 640x360; a arte tem 256x256).
@export var overlay_scale: float = 1.0
## Quadro (contando de 1) em que o bico abre e o chef derruba o item.
@export_range(1, 16) var peak_frame: int = 3
## Quanto tempo o pato fica gritando (repetindo os 2 últimos quadros).
@export var hold_time: float = 0.6
@export var fade_time: float = 0.35
@export var shake_strength: float = 3.0

@export_group("Efeito")
## Distância do Patolino até o chef para o quack pegar. 0 = qualquer lugar da tela.
@export var radius: float = 0.0
## Pulinho do item ao cair (pixels).
@export var drop_hop_height: float = 10.0
## Som do quack (opcional).
@export var sound: AudioStream


func _init() -> void:
	super._init()
	requires_target = false  # grita mesmo sem ninguém segurando nada


func _perform(_target: Node2D) -> void:
	if sound:
		var player := AudioStreamPlayer.new()
		player.stream = sound
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()

	var overlay := ScreenOverlayEffect.new()
	overlay.name = "QuackNaTela"
	overlay.sheet = overlay_sheet
	overlay.frame_size = frame_size
	overlay.fps = fps
	overlay.opacity = opacity
	overlay.overlay_scale = overlay_scale
	overlay.peak_frame = peak_frame
	overlay.hold_time = hold_time
	overlay.fade_time = fade_time
	overlay.shake_strength = shake_strength
	var state := {&"done": false}
	var on_peak := func() -> void:
		state[&"done"] = true
		_scare_everyone()
	overlay.peak_reached.connect(on_peak, CONNECT_ONE_SHOT)
	get_tree().current_scene.add_child(overlay)
	if not state[&"done"]:
		await overlay.peak_reached


## Todos os chefs no alcance derrubam o que estão segurando.
func _scare_everyone() -> void:
	var count: int = 0
	for node in get_tree().get_nodes_in_group(target_group):
		var chef := node as Node2D
		if chef == null or not CaptureComponent.is_available_target(chef):
			continue
		if radius > 0.0 and caster and caster.global_position.distance_to(chef.global_position) > radius:
			continue
		if HandComponent.force_drop(chef, drop_hop_height):
			count += 1
	items_dropped.emit(count)
