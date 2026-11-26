extends Node2D
class_name LevelSelectMap
## MAPA DE SELEÇÃO DE FASE (estilo Overcooked): os jogadores andam pelo mapa, param
## numa bandeira (`LevelSelectNode`) e apertam a tecla de confirmar para jogar.
##
## Serve para qualquer mapa: o Reino Caveira é só uma cena com arte + pontos.
## O mapa acha sozinho todos os `LevelSelectNode` que forem descendentes dele.
##
##   jogador em cima de uma bandeira -> HUD mostra número, nome, estrelas e a tecla
##   confirmar numa fase liberada com cena -> troca de cena (cortina do EasyTransition)
##   trancada -> bandeira treme + aviso   |   sem cena ainda -> "Em breve!"


## Um jogador confirmou uma fase jogável (antes de trocar de cena).
signal level_selected(node: LevelSelectNode)
## Confirmou uma fase trancada ou sem cena.
signal level_refused(node: LevelSelectNode, status: int)


@export var map_title: String = "Reino Caveira"

@export_group("Jogadores")
## Jogadores que andam no mapa (chef, Brasa...). A ordem casa com `confirm_actions`.
@export var players: Array[NodePath] = []
## Tecla de "jogar" de cada jogador (mesma ordem de `players`).
@export var confirm_actions: Array[StringName] = [&"chef_pick_drop", &"brasa_interact"]
## Nome de cada tecla para a dica do HUD (mesma ordem de `players`).
@export var confirm_key_names: Array[String] = ["ESPAÇO", "ENTER"]
## true = só começa com TODOS os jogadores em cima da bandeira.
@export var require_all_players: bool = false

@export_group("Início")
## Em qual ponto (índice na ordem da árvore) os jogadores aparecem.
@export var spawn_node_index: int = 0
## Distância de cada jogador para o centro do ponto inicial.
@export var spawn_spread: float = 18.0

@export_group("Progresso")
## Bandeira trancada abre quando a anterior (na ordem da árvore) tem pelo menos 1 estrela.
@export var unlock_in_order: bool = true

@export_group("Interface")
@export var hud_path: NodePath = ^"Interface"


## Resultados da sessão: id da fase ("1-1") -> melhor número de estrelas.
## (O jogo ainda não tem save: vale até fechar o jogo.)
static var results: Dictionary = {}
## Última fase jogada: os jogadores voltam para o mapa em cima dela.
static var last_level_id: String = ""


var nodes: Array[LevelSelectNode] = []
var _players: Array[Node2D] = []
var _starting: bool = false


@onready var hud: LevelSelectHUD = get_node_or_null(hud_path) as LevelSelectHUD


func _ready() -> void:
	DayNightSwitch.disable(self)
	_collect_nodes(self)
	_apply_progress()
	for path in players:
		var player := get_node_or_null(path) as Node2D
		if player:
			_players.append(player)
	_spawn_players()
	if hud:
		hud.setup(map_title, get_total_stars(), get_max_stars())


func _process(_delta: float) -> void:
	if hud == null or _starting:
		return
	var node: LevelSelectNode = get_focused_node()
	if node:
		hud.show_node(node, _hint_for(node))
	else:
		hud.hide_node()


func _input(event: InputEvent) -> void:
	if _starting or not event.is_pressed() or event.is_echo():
		return
	for i in _players.size():
		if i >= confirm_actions.size() or confirm_actions[i] == &"":
			continue
		if not InputMap.has_action(confirm_actions[i]) or not event.is_action_pressed(confirm_actions[i]):
			continue
		var node: LevelSelectNode = get_node_under(_players[i])
		if node:
			try_start(node)
			return


# --- Consultas ---------------------------------------------------------------------

## Ponto em que um jogador está agora (ou null).
func get_node_under(player: Node) -> LevelSelectNode:
	for node in nodes:
		if node.has_player(player):
			return node
	return null


## Ponto mostrado no HUD: o do primeiro jogador (na ordem de `players`) que estiver em um.
func get_focused_node() -> LevelSelectNode:
	for player in _players:
		var node: LevelSelectNode = get_node_under(player)
		if node:
			return node
	return null


func get_total_stars() -> int:
	var total: int = 0
	for node in nodes:
		total += node.stars
	return total


func get_max_stars() -> int:
	var total: int = 0
	for node in nodes:
		total += node.max_stars
	return total


# --- Ações -------------------------------------------------------------------------

func try_start(node: LevelSelectNode) -> bool:
	var status: int = node.get_status()
	if status == LevelSelectNode.Status.LOCKED:
		node.shake()
		_say(node, "Trancada!", Color(0.85, 0.8, 0.95))
		level_refused.emit(node, status)
		return false
	if status == LevelSelectNode.Status.COMING_SOON:
		node.shake()
		_say(node, "Em breve!", Color(1.0, 0.85, 0.4))
		level_refused.emit(node, status)
		return false
	if require_all_players and node.get_players().size() < _players.size():
		_say(node, "Todos na bandeira!", Color(1.0, 0.6, 0.5))
		return false
	_starting = true
	last_level_id = node.level_id
	level_selected.emit(node)
	if hud:
		hud.hide_node()
	change_scene(get_tree(), node.level_scene)
	return true


# --- Progresso (da sessão) ------------------------------------------------------

## Guarda o resultado de uma fase (fica o melhor). Chamado pela fase ao terminar.
static func record_result(level_id: String, stars: int) -> void:
	last_level_id = level_id
	results[level_id] = maxi(int(results.get(level_id, 0)), stars)


static func get_result(level_id: String) -> int:
	return int(results.get(level_id, 0))


func _apply_progress() -> void:
	var previous_done: bool = false
	for i in nodes.size():
		var node: LevelSelectNode = nodes[i]
		if results.has(node.level_id):
			node.stars = maxi(node.stars, get_result(node.level_id))
		if unlock_in_order and i > 0 and node.locked and previous_done:
			node.locked = false
		previous_done = get_result(node.level_id) > 0
		if node.level_id == last_level_id:
			spawn_node_index = i


func _say(node: LevelSelectNode, text: String, color: Color) -> void:
	FloatingText.spawn(get_parent() if get_parent() else self, node.global_position + Vector2(0, -44), text, color)
	if hud:
		hud.flash(text)


func _hint_for(node: LevelSelectNode) -> String:
	match node.get_status():
		LevelSelectNode.Status.LOCKED:
			return "Trancada - termine a fase anterior"
		LevelSelectNode.Status.COMING_SOON:
			return "Em breve"
	var keys: PackedStringArray = []
	for i in mini(_players.size(), confirm_key_names.size()):
		keys.append(confirm_key_names[i])
	return "%s para jogar" % " ou ".join(keys)


func _collect_nodes(root: Node) -> void:
	for child in root.get_children():
		if child is LevelSelectNode:
			nodes.append(child)
		_collect_nodes(child)


func _spawn_players() -> void:
	if nodes.is_empty() or _players.is_empty():
		return
	var start: LevelSelectNode = nodes[clampi(spawn_node_index, 0, nodes.size() - 1)]
	var count: int = _players.size()
	for i in count:
		var side: float = (i - (count - 1) / 2.0)
		_players[i].global_position = start.global_position + Vector2(side * spawn_spread * 2.0, 8.0)


## Troca de cena com a cortina do EasyTransition (se o projeto tiver), igual ao MvpFlow.
## Estática: a fase usa para voltar ao mapa.
static func change_scene(tree: SceneTree, path: String) -> void:
	var transition: Node = tree.root.get_node_or_null(^"EasyTransition")
	var animated: bool = transition != null and not transition.get(&"is_transitioning")
	if animated:
		await transition.cover(0.5, EasyTransitioner.TransitionAnim.CURTAIN)
	tree.paused = false
	tree.change_scene_to_file(path)
	if animated:
		await transition.uncover(0.5)
