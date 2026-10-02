extends FormigaSkill
## CAVAR (estilo jogo da toupeira): a formiga some num buraco e `hole_count` buracos
## aparecem em volta do chef. O buraco certo TREME antes dela sair.
##
## QTE de mouse: CLIQUE no buraco certo antes do bote. Uma chance só:
##   certo  -> frigideirada na formiga saindo do buraco (contra-ataque)
##   errado / demorou -> ela sai do buraco certo e morde o chef
## As formigas do fim da fila fazem buracos-disfarce tremerem também.


signal choice_made(index: int)


@export var hole_scene: PackedScene
@export_range(2, 8) var hole_count: int = 5
## Raios da roda de buracos em volta do chef.
@export var ring_radius: Vector2 = Vector2(64, 40)
## Quanto tempo o buraco certo treme.
@export var hint_time: float = 1.1
## Tempo para clicar depois que a dica acaba.
@export var react_time: float = 0.9
@export var counter_damage: int = 4


var _waiting: bool = false
var _round: int = 0


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	# 1. Entra no buraco.
	ant.health.invulnerable = true
	if ant.hp_bar:
		ant.hp_bar.set_bar_visible(false)
	var base_scale: Vector2 = ant.sprite.scale
	var dig := create_tween().set_parallel(true)
	dig.tween_property(ant.sprite, "scale", base_scale * Vector2(1.2, 0.0), 0.4)
	dig.tween_property(ant.sprite, "position", Vector2(0, 10), 0.4)
	await dig.finished
	ant.visible = false

	# 2. Buracos em volta do chef.
	var holes: Array[BuracoToupeira] = []
	for i in hole_count:
		var hole := hole_scene.instantiate() as BuracoToupeira
		battle.add_effect(hole)
		var angle: float = -PI * 0.5 + TAU * i / hole_count
		hole.global_position = chef.global_position + Vector2(cos(angle) * ring_radius.x, sin(angle) * ring_radius.y + 12.0)
		hole.index = i
		hole.appear()
		hole.chosen.connect(_on_hole_chosen)
		holes.append(hole)
	var correct: int = randi() % hole_count
	await battle.wait(0.45)

	# 3. Dica (e disfarces nas formigas mais espertas).
	for hole in holes:
		hole.set_clickable(true)
	holes[correct].tremble(1.0, hint_time)
	var decoys: int = clampi(ant.level - 1, 0, 2)
	var others: Array[BuracoToupeira] = []
	for hole in holes:
		if hole.index != correct:
			others.append(hole)
	others.shuffle()
	for d in decoys:
		others[d].tremble(0.6, hint_time * 0.6)
	battle.announce("Clique no buraco certo!", Color(1.0, 0.9, 0.5))

	_round += 1
	var this_round: int = _round
	_waiting = true
	get_tree().create_timer(hint_time + react_time, false).timeout.connect(func() -> void:
		if this_round == _round:
			_choose(-1))
	var choice: int = await choice_made
	for hole in holes:
		hole.set_clickable(false)

	# 4. Ela sai do buraco certo.
	var exit_hole: BuracoToupeira = holes[correct]
	exit_hole.burst()
	ant.global_position = exit_hole.global_position + Vector2(0, -6)
	ant.sprite.scale = base_scale
	ant.sprite.position = Vector2.ZERO
	ant.visible = true
	ant.health.invulnerable = false
	ant.face(chef.global_position, ant.art_faces_left)
	battle.register_qte(choice == correct)
	if choice == correct:
		chef.swing_pan(exit_hole.global_position - chef.global_position)
		battle.announce("Na mosca!", Color(0.55, 1.0, 0.55))
		ant.take_hit(counter_damage, exit_hole.global_position - chef.global_position)
		battle.shake(3.0, 0.2)
	else:
		if choice >= 0:
			holes[choice].show_empty()
			battle.announce("Buraco errado!", Color(1.0, 0.5, 0.4))
		else:
			battle.announce("Demorou!", Color(1.0, 0.5, 0.4))
		await ant.hop(14.0, 0.2)
		chef.take_hit(damage, chef.global_position - exit_hole.global_position)
		battle.shake(3.0, 0.2)
	await battle.wait(0.35)
	for hole in holes:
		hole.vanish()
	if ant.hp_bar and not ant.is_dead():
		ant.hp_bar.set_bar_visible(true)
	await ant.return_home(0.45)
	ant.face(chef.global_position, ant.art_faces_left)


func _on_hole_chosen(hole: BuracoToupeira) -> void:
	_choose(hole.index)


func _choose(index: int) -> void:
	if not _waiting:
		return
	_waiting = false
	choice_made.emit(index)
