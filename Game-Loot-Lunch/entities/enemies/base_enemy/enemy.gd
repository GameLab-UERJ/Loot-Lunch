extends Character
class_name Enemy

@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player") if get_tree().current_scene.has_node("player") else null
@onready var path_timer: Timer = get_node("PathTimer")
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
