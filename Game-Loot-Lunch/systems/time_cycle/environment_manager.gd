extends Node

signal outdoor_changed(is_outdoor: bool)

var is_outdoor : bool = true:
	set(value):
		if is_outdoor == value:
			return

		is_outdoor = value
		outdoor_changed.emit(value)
