extends Area2D
class_name Projectile
## PROJÉTIL genérico que causa dano (ovo, caveira de fogo, esfera de raio...).
##
## A cena `projetil.tscn` é a mesma para todos; o que muda é o ProjectileData (.tres):
## arte, velocidade, alcance, dano, se persegue o alvo...
##
##   - Encostou num corpo de `target_group` com `take_damage` -> dá dano e estoura
##   - Bateu numa parede (`world_mask`)                        -> estoura
##   - Voou `max_distance` sem acertar nada                    -> estoura no chão
##   - Se o dado tiver "surgir", ele primeiro aparece PARADO (sem acertar ninguém) e só
##     depois sai voando (mirando de novo no alvo, se `reaim_after_spawn`).
##   - Se o dado tiver `slow_percent`, quem for atingido fica lento (SlowComponent).
##
## Quem está invulnerável (ex.: no meio do dash) é ATRAVESSADO: dá para desviar com dash.
##
## Uso por código (qualquer um pode atirar: cliente, armadilha, chef...):
##     Projectile.spawn(cena, fase, dados, de_onde, direcao, quem_atirou, alvo)
##
## Estrutura da cena:
##   Projetil (Area2D, este script)
##   ├── CollisionShape2D   raio vem de `data.hit_radius`
##   ├── Sombra             AnimatedSprite2D no chão
##   ├── Visual (Node2D)    sobe e desce (arco)
##   │   └── Sprite         AnimatedSprite2D "voo"
##   └── Impacto            AnimatedSprite2D "impacto" (toca uma vez no fim)


signal hit(body: Node2D)
## Estourou (acertando alguém ou não). `position` = onde.
signal finished(at: Vector2)


const DEFAULT_SCENE_PATH: String = "res://restaurante/componentes/projetil/projetil.tscn"


@export var data: ProjectileData

## Quem atirou. Nunca é atingido pelo próprio projétil.
var shooter: Node = null
## Alvo (só usado se `data.homing_turn_speed > 0`).
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT

var _traveled: float = 0.0
var _finished: bool = false
## Tocando "surgir": parado e sem acertar ninguém.
var _spawning: bool = false


@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: AnimatedSprite2D = $Sombra
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var impact: AnimatedSprite2D = $Impacto


## Cria e lança um projétil. `scene` vazio = `projetil.tscn`.
static func spawn(scene: PackedScene, container: Node, projectile_data: ProjectileData,
		from: Vector2, dir: Vector2, who: Node = null, aim_target: Node2D = null) -> Projectile:
	if container == null or projectile_data == null or dir == Vector2.ZERO:
		return null
	if scene == null:
		scene = load(DEFAULT_SCENE_PATH) as PackedScene
	var projectile := scene.instantiate() as Projectile
	if projectile == null:
		push_error("Projectile.spawn: a cena não tem o script Projectile na raiz.")
		return null
	projectile.data = projectile_data
	projectile.shooter = who
	projectile.target = aim_target
	projectile.direction = dir.normalized()
	container.add_child(projectile)
	projectile.global_position = from
	return projectile


func _ready() -> void:
	if data == null:
		push_warning("Projectile '%s' sem ProjectileData." % name)
		queue_free()
		return

	collision_layer = 0
	collision_mask = data.world_mask | data.target_mask
	monitorable = false

	var circle := CircleShape2D.new()
	circle.radius = data.hit_radius
	collision_shape.shape = circle

	var frames: SpriteFrames = data.build_frames()
	for animated in [sprite, shadow, impact]:
		animated.sprite_frames = frames
		animated.scale = data.sprite_scale

	sprite.visible = data.has_part(&"voo")
	if data.has_part(&"surgir"):
		_spawning = true
		sprite.visible = true
		sprite.play(&"surgir")
		sprite.animation_finished.connect(_on_spawn_finished, CONNECT_ONE_SHOT)
	elif sprite.visible:
		sprite.play(&"voo")

	shadow.visible = data.has_part(&"sombra")
	shadow.modulate.a = data.shadow_opacity
	if shadow.visible:
		shadow.animation = &"sombra"
		shadow.pause()

	impact.visible = false
	impact.animation_finished.connect(queue_free)
	_update_visual()


func _physics_process(delta: float) -> void:
	if _finished or _spawning:
		return

	_steer(delta)
	var step: float = data.speed * delta
	global_position += direction * step
	_traveled += step
	_update_visual()

	for body in get_overlapping_bodies():
		if _is_shooter(body):
			continue
		if _can_damage(body):
			_hit_body(body)
			return
		if _is_invulnerable(body):
			continue  # desviou com dash: atravessa
		if body is CollisionObject2D and (body.collision_layer & data.world_mask) != 0:
			_finish()
			return

	if _traveled >= data.max_distance:
		_finish()


## Estoura agora (onde estiver). Público para quem quiser cancelar o projétil.
func pop() -> void:
	_finish()


func _steer(delta: float) -> void:
	if data.homing_turn_speed <= 0.0 or not is_instance_valid(target):
		return
	var wanted: Vector2 = (target.global_position - global_position)
	if wanted == Vector2.ZERO:
		return
	var max_turn: float = deg_to_rad(data.homing_turn_speed) * delta
	var angle: float = direction.angle_to(wanted.normalized())
	direction = direction.rotated(clampf(angle, -max_turn, max_turn))


func _update_visual() -> void:
	var t: float = clampf(_traveled / maxf(data.max_distance, 1.0), 0.0, 1.0)
	var height: float = sin(t * PI) * data.arc_height
	visual.position.y = -height
	if data.rotate_with_direction:
		sprite.rotation = direction.angle()
	if data.flip_with_direction and not is_zero_approx(direction.x):
		sprite.flip_h = direction.x < 0.0
		impact.flip_h = sprite.flip_h

	# Sombra: quadro maior perto do chão, menor no alto do arco.
	var shadow_frames: int = data.shadow_frame_count
	if shadow.visible and shadow_frames > 1 and data.arc_height > 0.0:
		var ratio: float = height / data.arc_height
		shadow.frame = clampi(roundi(ratio * (shadow_frames - 1)), 0, shadow_frames - 1)


func _is_shooter(body: Node) -> bool:
	return body == shooter or (shooter != null and shooter.is_ancestor_of(body))


func _is_invulnerable(body: Node) -> bool:
	return body.get(&"is_invulnerable") == true


func _can_damage(body: Node) -> bool:
	if not body.has_method(&"take_damage") or _is_invulnerable(body):
		return false
	if data.target_group != &"" and not body.is_in_group(data.target_group):
		return false
	if body is CollisionObject2D and (body.collision_layer & data.target_mask) == 0:
		return false
	return true


func _hit_body(body: Node2D) -> void:
	body.take_damage(data.damage, direction, data.knockback)
	if data.slow_percent > 0.0 and data.slow_duration > 0.0:
		# A fonte é o DADO: duas caveiras seguidas renovam a lentidão, não empilham.
		SlowComponent.apply(body, data, data.slow_percent, data.slow_duration, data.slow_tint)
	hit.emit(body)
	_finish()


func _on_spawn_finished() -> void:
	if _finished or not is_inside_tree():
		return
	_spawning = false
	if data.reaim_after_spawn and is_instance_valid(target):
		var wanted: Vector2 = target.global_position - global_position
		if wanted != Vector2.ZERO:
			direction = wanted.normalized()
	sprite.visible = data.has_part(&"voo")
	if sprite.visible:
		sprite.play(&"voo")
	_update_visual()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_deferred(&"monitoring", false)
	visual.visible = false
	shadow.visible = false
	finished.emit(global_position)

	if data.has_part(&"impacto"):
		impact.visible = true
		impact.play(&"impacto")
	else:
		queue_free()
