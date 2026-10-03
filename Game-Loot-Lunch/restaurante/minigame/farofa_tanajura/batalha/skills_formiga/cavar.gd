extends FormigaSkill
## CAVAR (estilo jogo da toupeira): a formiga AFUNDA no chão (cortada pela linha do
## chão, com a terra explodindo — cavar_erupcao) e `hole_count` buracos aparecem em
## volta do chef. O buraco certo TREME antes dela sair.
##
## QTE de mouse: CLIQUE no buraco certo antes do bote. Uma chance só:
##   certo  -> MARTELADA na formiga saindo do buraco (contra-ataque, ela fica tonta)
##   errado / demorou -> ela sai do buraco certo e morde o chef
## As formigas do fim da fila fazem buracos-disfarce tremerem também.


signal choice_made(index: int)


@export var hole_scene: PackedScene
@export_range(2, 8) var hole_count: int = 5
## Raios da roda de buracos em volta do chef.
@export var ring_radius: Vector2 = Vector2(92, 52)
## Quanto tempo o buraco certo treme.
@export var hint_time: float = 1.0
## Tempo para clicar depois que a dica acaba.
@export var react_time: float = 0.8
@export var sink_depth: float = 90.0
@export var erupt_anim: SheetAnimation


var _waiting: bool = false
var _round: int = 0


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	# 1. Entra no chão.
	ant.health.invulnerable = true
	if ant.hp_bar:
		ant.hp_bar.set_bar_visible(false)
	battle.fx(erupt_anim, ant.feet_position())
	await ant.sink_into_ground(sink_depth, 0.45)
	ant.visible = false

	# 2. Buracos em volta do chef.
	var holes: Array[BuracoToupeira] = []
	var center: Vector2 = chef.feet_position()
	for i in hole_count:
		var hole := hole_scene.instantiate() as BuracoToupeira
		battle.add_effect(hole)
		var angle: float = -PI * 0.5 + TAU * i / hole_count
		hole.global_position = center + Vector2(cos(angle) * ring_radius.x, sin(angle) * ring_radius.y)
		hole.index = i
		hole.appear()
		hole.chosen.connect(_on_hole_chosen)
		holes.append(hole)
	var correct: int = randi() % hole_count
	await battle.wait(0.4)

	# 3. Dica (e disfarces nas formigas mais espertas).
	for hole in holes:
		hole.set_clickable(true)
	var hint: float = hint_time * (1.0 - 0.05 * ant.level)
	holes[correct].tremble(1.0, hint)
	var decoys: int = clampi(ant.level - 1, 0, 2)
	var others: Array[BuracoToupeira] = []
	for hole in holes:
		if hole.index != correct:
			others.append(hole)
	others.shuffle()
	for d in decoys:
		others[d].tremble(0.6, hint * 0.6)
	battle.announce("Clique no buraco certo!", Color(1.0, 0.9, 0.5))

	_round += 1
	var this_round: int = _round
	_waiting = true
	get_tree().create_timer(hint + react_time, false).timeout.connect(func() -> void:
		if this_round == _round:
			_choose(-1))
	var choice: int = await choice_made
	for hole in holes:
		hole.set_clickable(false)

	# 4. Ela sai do buraco certo.
	var exit_hole: BuracoToupeira = holes[correct]
	exit_hole.burst()
	battle.fx(erupt_anim, exit_hole.global_position)
	ant.global_position = exit_hole.global_position - Vector2(0, ant.ground_offset - 4)
	ant.visible = true
	ant.face(chef.global_position, ant.art_faces_left)
	await ant.rise_from_ground(sink_depth * 0.5, 0.18)
	ant.health.invulnerable = false
	battle.register_qte(choice == correct)
	if choice == correct:
		battle.announce("Na mosca!", Color(0.55, 1.0, 0.55))
		# O chef pula até o buraco e desce a frigideira como um martelo.
		var side: float = -1.0 if exit_hole.global_position.x < chef.global_position.x else 1.0
		await chef.move_to(exit_hole.global_position + Vector2(-58.0 * side, -chef.ground_offset), 0.12)
		await counter(battle, ant, chef, Vector2(-24.0 * side, -6))
		await chef.finish_action()
		chef.return_home(0.25)
	else:
		if choice >= 0:
			holes[choice].show_empty()
			battle.announce("Buraco errado!", Color(1.0, 0.5, 0.4))
		else:
			battle.announce("Demorou!", Color(1.0, 0.5, 0.4))
		await ant.hop(14.0, 0.2)
		chef.take_hit(damage, chef.global_position - exit_hole.global_position)
		battle.shake(3.0, 0.2)
	await battle.wait(0.3)
	for hole in holes:
		hole.vanish()
	if ant.hp_bar and not ant.is_dead():
		ant.hp_bar.set_bar_visible(true)
	await ant.return_home(0.4)
	ant.face(chef.global_position, ant.art_faces_left)


func _on_hole_chosen(hole: BuracoToupeira) -> void:
	_choose(hole.index)


func _choose(index: int) -> void:
	if not _waiting:
		return
	_waiting = false
	choice_made.emit(index)
