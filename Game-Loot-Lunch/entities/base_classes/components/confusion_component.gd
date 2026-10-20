extends StatusEffectComponent
class_name ConfusionComponent
## CONFUSO (nuvem do Johnny): as setas ficam INVERTIDAS. Apertou para a esquerda, o
## personagem vai para a direita; cima vira baixo, e assim por diante.
##
##     ConfusionComponent.apply(chef, fonte, 120.0, arte_do_confuso)
##     ConfusionComponent.is_active_on(chef)
##     dir = ConfusionComponent.transform_direction(chef, dir)   # quem lê o controle
##
## O componente não mexe no controle sozinho: quem transforma a direção lida do teclado
## em movimento (o chef) chama `transform_direction`. Assim serve para qualquer controle
## (teclado, joystick, IA...).


const NODE_NAME: StringName = &"ConfusionComponent"


## Inverte esquerda/direita.
@export var invert_horizontal: bool = true
## Inverte cima/baixo.
@export var invert_vertical: bool = true


static func apply(target: Node, source: Variant, duration: float,
		visual: SheetAnimation = null) -> ConfusionComponent:
	return _apply_status(ConfusionComponent, NODE_NAME, target, source, duration, visual) \
		as ConfusionComponent


static func find_in(target: Node) -> ConfusionComponent:
	return _find_status(ConfusionComponent, NODE_NAME, target) as ConfusionComponent


static func is_active_on(target: Node) -> bool:
	var component: ConfusionComponent = find_in(target)
	return component != null and component.is_active()


static func remove(target: Node, source: Variant) -> void:
	var component: ConfusionComponent = find_in(target)
	if component:
		component.remove_source(source)


## A direção que o personagem deve andar de verdade (invertida se estiver confuso).
static func transform_direction(target: Node, direction: Vector2) -> Vector2:
	var component: ConfusionComponent = find_in(target)
	if component == null or not component.is_active():
		return direction
	return component.invert(direction)


func invert(direction: Vector2) -> Vector2:
	return Vector2(
		-direction.x if invert_horizontal else direction.x,
		-direction.y if invert_vertical else direction.y
	)
