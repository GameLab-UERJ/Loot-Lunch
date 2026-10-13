extends RefCounted
class_name MvpFlow
## NAVEGAÇÃO do MVP: o único lugar que sabe a ORDEM das telas.
##
##   Menu (main_menu_rest)  --Jogar-->  Fase 1 (lvl_1)  --fim do turno-->  Boss VIP
##        ^                               |  chef caiu: tentar de novo / sair       |
##        |                               v                                         v
##        +------------- Sair ------------+------- Sair ------  Agradecimento <-- venceu
##
## As cenas do jogo (lvl_1.tscn, boss_fight_vip.tscn) NÃO sabem do MVP: ao abrir uma
## delas, o MvpFlow pendura um nó de fluxo (fluxo_fase_1.tscn / fluxo_boss_vip.tscn)
## que escuta o fim da cena e chama a próxima tela. Abrindo a cena sozinha (F6) ela
## continua funcionando como antes, sem o fluxo.
##
## "Sair" sempre volta ao menu e "Jogar" sempre começa da Fase 1 (o MVP não tem save).
##
## Uso (de qualquer nó):  MvpFlow.play_level_1(get_tree())


const MAIN_MENU: String = "res://restaurante/UI/main_menu_rest.tscn"
const LEVEL_1: String = "res://restaurante/leveis/lvl_1/lvl_1.tscn"
const BOSS_FIGHT: String = "res://restaurante/minigame/boss_fight_vip.tscn"
const THANKS: String = "res://restaurante/mvp/agradecimento.tscn"

const LEVEL_1_FLOW: String = "res://restaurante/mvp/fluxo_fase_1.tscn"
const BOSS_FLOW: String = "res://restaurante/mvp/fluxo_boss_vip.tscn"

## Duração total da transição (cobrir + descobrir), em segundos.
const TRANSITION_TIME: float = 1.0


static func go_to_main_menu(tree: SceneTree) -> void:
	_go(tree, func() -> Node: return _instantiate(MAIN_MENU))


## Fase 1 do zero (também é o "tentar de novo" quando o chef cai).
static func play_level_1(tree: SceneTree) -> void:
	_go(tree, func() -> Node: return _with_flow(LEVEL_1, LEVEL_1_FLOW))


## Boss fight do Cliente VIP do começo (também é o "tentar de novo" dela).
static func play_boss_fight(tree: SceneTree) -> void:
	_go(tree, func() -> Node: return _with_flow(BOSS_FIGHT, BOSS_FLOW))


static func go_to_thanks(tree: SceneTree) -> void:
	_go(tree, func() -> Node: return _instantiate(THANKS))


# --- Interno --------------------------------------------------------------------

static func _instantiate(path: String) -> Node:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("MvpFlow: não achei a cena '%s'." % path)
		return null
	return scene.instantiate()


## Instancia a cena do jogo e pendura nela o nó de fluxo do MVP (último filho).
static func _with_flow(scene_path: String, flow_path: String) -> Node:
	var root: Node = _instantiate(scene_path)
	var flow: Node = _instantiate(flow_path)
	if root and flow:
		root.add_child(flow)
	return root


## Cobre a tela, troca de cena (com o jogo despausado) e descobre.
## Usa o EasyTransition do projeto se ele existir; sem ele, troca direto.
static func _go(tree: SceneTree, build: Callable) -> void:
	var transition: Node = tree.root.get_node_or_null(^"EasyTransition")
	var animated: bool = transition != null and not transition.get(&"is_transitioning")
	if animated:
		await transition.cover(TRANSITION_TIME * 0.5, EasyTransitioner.TransitionAnim.CURTAIN)
	var scene: Node = build.call()
	if scene == null:
		if animated:
			transition.uncover(TRANSITION_TIME * 0.5)
		return
	# A fase pausa a árvore no fim do turno: a próxima cena precisa começar rodando.
	tree.paused = false
	tree.change_scene_to_node(scene)
	if animated:
		await transition.uncover(TRANSITION_TIME * 0.5)
