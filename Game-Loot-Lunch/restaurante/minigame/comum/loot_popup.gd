extends Sprite2D
class_name LootPopup
## "VOCÊ GANHOU UM ITEM!": o ícone do item salta de onde o inimigo caiu, faz um arco até
## quem ganhou e some com um brilho, com o nome do item subindo (FloatingText).
##
##   await LootPopup.play(self, icone, onde_caiu, chef.global_position, "Asa de Formiga Rainha")
##
## Só a ANIMAÇÃO: entregar o item de verdade (inventário) fica com quem chama.
## Reutilizável: drops de chefe, baús, recompensas de fase.


## Toca a animação inteira e espera acabar.
static func play(parent: Node, icon: Texture2D, from: Vector2, to: Vector2, item_name: String,
		icon_scale: float = 1.0, color: Color = Color(1.0, 0.85, 0.35)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var popup := LootPopup.new()
	popup.texture = icon
	popup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	popup.z_index = 80
	parent.add_child(popup)
	popup.global_position = from
	await popup._run(from, to, item_name, icon_scale, color)


func _run(from: Vector2, to: Vector2, item_name: String, icon_scale: float, color: Color) -> void:
	var full := Vector2.ONE * icon_scale
	scale = Vector2.ZERO
	# 1. Salta para cima girando um pouco.
	var pop := create_tween().set_parallel(true)
	pop.tween_property(self, "scale", full, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "global_position", from + Vector2(0, -40), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "rotation", TAU, 0.5)
	await pop.finished
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -26), item_name, color)
	# 2. Brilha no ar (o jogador lê o nome).
	var glow := create_tween().set_loops(3)
	glow.tween_property(self, "modulate", Color(1.8, 1.7, 1.2), 0.15)
	glow.tween_property(self, "modulate", Color.WHITE, 0.15)
	await glow.finished
	# 3. Arco até quem ganhou e encolhe "para dentro da mochila".
	var start: Vector2 = global_position
	var fly := create_tween()
	fly.tween_method(func(t: float) -> void:
		global_position = start.lerp(to, t) + Vector2(0, -50.0 * sin(PI * t))
		scale = full * lerpf(1.0, 0.25, t), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await fly.finished
	FloatingText.spawn(get_parent(), to + Vector2(0, -44), "+1", Color(0.6, 1.0, 0.6))
	queue_free()
