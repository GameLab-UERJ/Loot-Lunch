extends Resource

class_name DropData


@export var item: PackedScene
@export_range(0, 100, 1, "suffix:%") var probability
@export_range(0, 10, 1, "suffix:itens") var min_amount: int = 1
@export_range(0, 10, 1, "suffix:itens") var max_amount: int = 1


func get_drop_count() -> int:
	if randi_range(0, 100) >= probability:
		return 0
	
	return randi_range(min_amount, max_amount)
