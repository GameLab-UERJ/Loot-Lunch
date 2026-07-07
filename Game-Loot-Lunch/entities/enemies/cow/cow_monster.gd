extends Enemy
class_name CowMonster


@export var patrol_speed : int = 50
@export var attack_speed : int = 300


var is_player_in_sight : bool = false
var _patrol_marker : Marker2D


@onready var base_machine_player: StateMachinePlayer = $BaseMachinePlayer
@onready var enabled_machine_player: StateMachinePlayer = $BaseMachinePlayer/EnabledMachinePlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var drop_component: DropComponent = $DropComponent
@onready var flip_sprite_component: FlipSpriteComponent = $FlipSpriteComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_patrol_marker = Marker2D.new()
	get_tree().current_scene.call_deferred("add_child",_patrol_marker)


func _process(delta: float) -> void:
	super._process(delta)
	enabled_machine_player.set_param("is_player_in_sight",is_player_in_sight)
	movement_component.move()


func _on_got_hurt() -> void:
	enabled_machine_player.attack()


func _on_died() -> void:
	base_machine_player.set_trigger("died")
	flip_sprite_component.disable()
	hitbox_component.collision_mask = 0
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(0.5).timeout
	drop_component.drop_items()


func _on_drop_component_drop_finished() -> void:
	await create_tween().tween_property(animated_sprite,"modulate",Color.TRANSPARENT,10).finished
	queue_free()


func _on_player_in_sight() -> void:
	is_player_in_sight = true


func _on_player_out_of_sight() -> void:
	is_player_in_sight = false


func _on_enabled_state_changed(from: Variant, to: Variant) -> void:
	match from:
		"Alerted":
			flip_sprite_component.node_to_face = null
		"Attacking","Patrol":
			movement_component.default_direction = Vector2.ZERO
	
	match to:
		"Idle":
			animated_sprite.play("idle")
		"Alerted":
			animated_sprite.play("alert")
			flip_sprite_component.node_to_face = player
		"Attacking":
			animated_sprite.play("attack")
			movement_component.max_speed = attack_speed
			movement_component.default_direction = global_position.direction_to(player.global_position)
		"Patrol":
			animated_sprite.play("walk")
			_patrol_marker.global_position = global_position + Vector2( (randi_range(0,1)*2+-1)* randi_range(10,50),
																		(randi_range(0,1)*2+-1)* randi_range(10,50))
			movement_component.max_speed = patrol_speed
			movement_component.default_direction = global_position.direction_to(_patrol_marker.global_position)


func _on_enabled_machine_player_updated(state: Variant, _delta: Variant) -> void:
	match state:
		"Patrol":
			if abs(global_position.distance_to(_patrol_marker.global_position)) < 5:
				enabled_machine_player.finish_patrol()


func _on_base_state_changed(_from: Variant, to: Variant) -> void:
	match to:
		"Dead":
			animated_sprite.play("die")


func _on_hitbox_component_hit() -> void:
	enabled_machine_player.finish_attack()
