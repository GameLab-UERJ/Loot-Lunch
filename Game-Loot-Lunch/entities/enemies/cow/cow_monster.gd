extends Enemy
class_name CowMonster


var is_player_in_sight : bool = false


@onready var base_machine_player: StateMachinePlayer = $BaseMachinePlayer
@onready var enabled_machine_player: StateMachinePlayer = $BaseMachinePlayer/EnabledMachinePlayer
@onready var drop_component: DropComponent = $DropComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


'''
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_attack"):
		if base_machine_player.current == "Disabled":
			base_machine_player.set_param("enabled",true)
		else:
			base_machine_player.set_param("enabled",false)
	if event.is_action_released("ui_accept"):
		take_damage(1000,Vector2.ZERO,0)
'''


func _process(delta: float) -> void:
	super._process(delta)
	enabled_machine_player.set_param("is_player_in_sight",is_player_in_sight)


func _on_died() -> void:
	base_machine_player.set_trigger("died")
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
	match to:
		"Idle":
			animated_sprite.play("idle")
