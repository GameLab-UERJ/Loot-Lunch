extends PanelContainer
class_name Inventory


@export var dimensions : Vector2i:	## Dimensão do inventário, x representando a quantidade de colunas e y a quantidade de linhas
	set = set_dimensions


@onready var grid: GridContainer = $Grid


func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	pass


func set_dimensions(value : Vector2i) -> void:
	if not dimensions or not(dimensions.x != 0 and dimensions.y != 0):
		push_error("Dimension of Inventory can't have zero rows or columns")
		return
	dimensions = value
