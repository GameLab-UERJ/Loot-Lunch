extends Node2D
class_name InternalDungeon

signal player_can_leave_dungeon

func _ready() -> void:
	pass

# Quando o player quiser sair da dungeon
func _on_exit_area_entered() -> void:
	player_can_leave_dungeon.emit()
