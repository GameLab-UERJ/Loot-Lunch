extends StatusEffectComponent
class_name StunComponent
## ATORDOADO (stun de choque do Johnny, e o que mais vier): o personagem fica PARADO
## e não faz nada (não anda, não dá dash, não interage, não usa habilidade).
##
## Atordoado NÃO é invencível: pode (e vai) ser atingido por outras magias.
##
##     StunComponent.apply(chef, fonte, 2.0, arte_do_choque)
##     StunComponent.is_active_on(chef)
##
## Como funciona sem o chef saber de nada:
##   - roda ANTES do `move_and_slide()` do personagem (`process_physics_priority` negativo)
##     e zera a `velocity` todo quadro -> ele não sai do lugar (nem com empurrão);
##   - ao começar, chama `interrupt_abilities()` do personagem, se existir (larga o Q).
## O chef ainda pergunta `is_stunned()` para bloquear teclas (dash, B, R, habilidades).


const NODE_NAME: StringName = &"StunComponent"


static func apply(target: Node, source: Variant, duration: float,
		visual: SheetAnimation = null) -> StunComponent:
	return _apply_status(StunComponent, NODE_NAME, target, source, duration, visual) as StunComponent


static func find_in(target: Node) -> StunComponent:
	return _find_status(StunComponent, NODE_NAME, target) as StunComponent


static func is_active_on(target: Node) -> bool:
	var component: StunComponent = find_in(target)
	return component != null and component.is_active()


static func remove(target: Node, source: Variant) -> void:
	var component: StunComponent = find_in(target)
	if component:
		component.remove_source(source)


func _init() -> void:
	process_physics_priority = -100  # antes do move_and_slide do personagem


func _on_started() -> void:
	var target: Node = get_parent()
	if target.has_method(&"interrupt_abilities"):
		target.interrupt_abilities()
	_freeze()


func _on_active_physics(_delta: float) -> void:
	_freeze()


func _freeze() -> void:
	var body := get_parent() as CharacterBody2D
	if body:
		body.velocity = Vector2.ZERO
