extends CustomerAbility
class_name ProjectileAbility
## MAGIA DE PROJÉTIL genérica: atira um Projectile no alvo (ovo do Patolino, caveira de
## fogo da Mandy, esfera de raio do Johnny...). O tipo do projétil é DADO (`data`, .tres).
##
## Mira no lugar onde o chef ESTAVA no momento do arremesso, então dá para desviar
## andando ou com dash (a não ser que o ProjectileData seja teleguiado).


signal fired(projectile: Projectile)


@export_group("Projétil")
## O que é atirado (arte, velocidade, dano...).
@export var data: ProjectileData
## Cena do projétil. Vazio = `projetil.tscn` (serve para quase tudo).
@export var projectile_scene: PackedScene
## De onde sai, relativo ao cliente (ex.: a mão / o bico).
@export var spawn_offset: Vector2 = Vector2(0, -6)
## Quantos projéteis por uso (em leque).
@export_range(1, 12) var amount: int = 1
## Abertura do leque em graus (só com `amount` > 1).
@export_range(0.0, 180.0) var spread_degrees: float = 20.0


func _perform(target: Node2D) -> void:
	if data == null or caster == null:
		return
	var from: Vector2 = caster.global_position + spawn_offset
	var aim: Vector2 = (target.global_position - from) if target else Vector2.DOWN
	if aim == Vector2.ZERO:
		aim = Vector2.DOWN

	for i in amount:
		var angle: float = 0.0
		if amount > 1:
			angle = deg_to_rad(lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, i / float(amount - 1)))
		var projectile: Projectile = Projectile.spawn(projectile_scene, get_world(), data, from,
				aim.rotated(angle), caster, target)
		if projectile:
			fired.emit(projectile)
