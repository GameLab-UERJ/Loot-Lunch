extends Node
class_name PriceManager


@export var price_label : Label


func set_price_text(value : String, color : Color = Color.WHITE) -> void:
	price_label.text = "$ " + value
	if price_label.label_settings:
		price_label.label_settings = price_label.label_settings.duplicate()
		price_label.label_settings.font_color = color
	price_label.add_theme_color_override("font_color", color)
	price_label.visible = not value.is_empty()
