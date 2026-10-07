extends Node2D
class_name FarofaCutscene
## ANIMAÇÃO do fim da Fase 3: os 5 drops (bundas de tanajura) voam para a tábua, o chef corta uma
## por uma, joga na frigideira, despeja a farinha, mexe e... FAROFA DE TANAJURA!
##
## Só tweens (sem AnimationPlayer), então funciona com qualquer quantidade de drops:
##     await cutscene.play(chef, [posição_do_drop_1, ...])
## O chef é qualquer Battler (usa move_to / squash / hop).


signal finished


@export var board: Node2D
@export var pan: Node2D
@export var flour_bowl: Node2D
@export var bunda_texture: Texture2D
@export var cut_texture: Texture2D
@export var farofa_texture: Texture2D
## Onde o chef fica para cortar (ao lado da tábua).
@export var chef_spot: Marker2D
@export var piece_scale: Vector2 = Vector2(1.5, 1.5)
## Escala do drop no chão da luta (dropTanajura) e quando ele pousa na tábua.
@export var drop_scale: Vector2 = Vector2(1.5, 1.5)
@export var bunda_board_scale: Vector2 = Vector2(0.7, 0.7)


var _pieces: Array[Sprite2D] = []


func _ready() -> void:
	hide()


func play(chef: Battler, drop_spots: Array[Vector2]) -> void:
	show()
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, 0.3).finished

	# 1. Drops: as bundas saltam dos corpos para a tábua.
	for i in drop_spots.size():
		var piece := Sprite2D.new()
		piece.texture = bunda_texture
		piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		piece.scale = drop_scale
		piece.z_index = 20
		get_parent().add_child(piece)
		piece.global_position = drop_spots[i]
		_pieces.append(piece)
		var spread: float = (i - (drop_spots.size() - 1) * 0.5) * 9.0
		var to: Vector2 = board.global_position + Vector2(spread, -4)
		_arc(piece, drop_spots[i], to, 0.5, 40.0)
		create_tween().tween_property(piece, "scale", bunda_board_scale, 0.5)
		FloatingText.spawn(get_parent(), drop_spots[i] + Vector2(0, -12), "Bunda de tanajura!", Color(1.0, 0.8, 0.5))
		await _wait(0.18)
	await _wait(0.5)

	# 2. O chef vai até a tábua e corta.
	await chef.move_to(chef_spot.global_position, 0.6)
	chef.face(board.global_position)
	for piece in _pieces:
		await chef.squash(Vector2(1.15, 0.85), 0.12)
		piece.texture = cut_texture
		piece.scale = piece_scale * 1.4
		create_tween().tween_property(piece, "scale", piece_scale, 0.12)
		FloatingText.spawn(get_parent(), piece.global_position + Vector2(0, -10), "Tchac!", Color.WHITE)
		await _wait(0.12)

	# 3. Para a frigideira.
	for piece in _pieces:
		_arc(piece, piece.global_position, pan.global_position + Vector2(randf_range(-6, 6), -4), 0.35, 26.0)
		create_tween().tween_property(piece, "scale", piece_scale * 0.6, 0.35)
		await _wait(0.1)
	await _wait(0.4)

	# 4. Farinha.
	var bowl_rest: Vector2 = flour_bowl.position
	var pour := create_tween()
	pour.tween_property(flour_bowl, "global_position", pan.global_position + Vector2(12, -26), 0.3)
	pour.tween_property(flour_bowl, "rotation", deg_to_rad(-55.0), 0.2)
	await pour.finished
	for i in 16:
		_flour_grain()
		await _wait(0.04)
	var back := create_tween()
	back.tween_property(flour_bowl, "rotation", 0.0, 0.15)
	back.tween_property(flour_bowl, "position", bowl_rest, 0.3)

	# 5. Mexe a frigideira.
	FloatingText.spawn(get_parent(), pan.global_position + Vector2(0, -24), "Mexe, mexe!", Color(1.0, 0.9, 0.6))
	var stir := create_tween()
	for i in 8:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		stir.tween_property(pan, "rotation", deg_to_rad(12.0) * side, 0.08)
	stir.tween_property(pan, "rotation", 0.0, 0.08)
	chef.hop(8.0, 0.3)
	await stir.finished
	for piece in _pieces:
		piece.queue_free()
	_pieces.clear()

	# 6. Pronto!
	var farofa := Sprite2D.new()
	farofa.texture = farofa_texture
	farofa.z_index = 25
	get_parent().add_child(farofa)
	farofa.global_position = pan.global_position + Vector2(0, -26)
	farofa.scale = Vector2.ZERO
	await create_tween().tween_property(farofa, "scale", Vector2(3, 3), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished
	FloatingText.spawn(get_parent(), farofa.global_position + Vector2(0, -40), "FAROFA DE TANAJURA!", Color(1.0, 0.85, 0.3))
	await chef.hop(16.0, 0.4)
	await _wait(0.8)
	finished.emit()


func _arc(node: Node2D, from: Vector2, to: Vector2, duration: float, height: float) -> void:
	var tween := create_tween()
	tween.tween_method(_place_on_arc.bind(node, from, to, height), 0.0, 1.0, duration)


func _place_on_arc(t: float, node, from: Vector2, to: Vector2, height: float) -> void:
	if is_instance_valid(node):
		node.global_position = from.lerp(to, t) + Vector2(0.0, -height * sin(PI * t))


func _flour_grain() -> void:
	var grain := ColorRect.new()
	grain.color = Color(0.99, 0.97, 0.92) if randf() > 0.4 else Color(0.93, 0.89, 0.77)
	grain.size = Vector2(2, 2)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.z_index = 30
	get_parent().add_child(grain)
	var from: Vector2 = flour_bowl.global_position + Vector2(-8, 4)
	grain.global_position = from
	var tween := create_tween().set_parallel(true)
	tween.tween_property(grain, "global_position", pan.global_position + Vector2(randf_range(-8, 8), -2), 0.3)
	tween.tween_property(grain, "modulate:a", 0.0, 0.1).set_delay(0.25)
	tween.chain().tween_callback(grain.queue_free)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
