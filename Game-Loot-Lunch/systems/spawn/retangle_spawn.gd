extends Spawn
class_name RetangleSpawn


@export var chased_node : Node2D

var center: Vector2
var size: Vector2
var limit_up: float
var limit_down: float
var limit_right: float
var limit_left: float

@onready var spawn_area: CollisionShape2D = $SpawnArea/CollisionShape2D

func _ready() -> void:
	super()
	
	center = spawn_area.global_position
	limit_up = center.y + spawn_area.shape.size.y / 2
	limit_down = center.y - spawn_area.shape.size.y / 2
	limit_right = center.x + spawn_area.shape.size.x / 2
	limit_left = center.x - spawn_area.shape.size.x / 2


func _on_spawned(spawned_creature: Character) -> void:
	if chased_node:
		spawned_creature.player = chased_node
		if spawned_creature.has_node('ChaseComponent'):
			spawned_creature.chase_component.chased_node = chased_node
	
	spawned_creature.global_position = get_valid_point()


# Returns a valid point inside retangle
func get_valid_point() -> Vector2:
	return Vector2(
		randf_range(limit_left, limit_right), 
		randf_range(limit_down, limit_up)
		)
