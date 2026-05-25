extends Node2D


var combat_zone : Node2D


@onready var inside_house: Node2D = get_node("InsideHouse") if self.has_node("InsideHouse") else null
@onready var external_house: Node2D = get_node("ExternalHouse") if self.has_node("ExternalHouse") else null
@onready var shop_room: Node2D = get_node("ShopRoom") if self.has_node("ShopRoom") else null



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not combat_zone:
		combat_zone = load("uid://d0pechf47plm7").instantiate()
	if not inside_house:
		inside_house = load("uid://beai1me2j13ef").instantiate()
	if not external_house:
		external_house = load("uid://d3ypiu36avnv1").instantiate()
	if not shop_room:
		shop_room = load("uid://dccphg7sgqmy7").instantiate()



func _on_player_can_leave_house() -> void:
	external_house.get_node("ExternalHouse").player_start_position = external_house.get_node("HouseEntrance")
	EasyTransition.transition_to_node(external_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_house() -> void:
	EasyTransition.transition_to_node(inside_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_leave_shop() -> void:
	external_house.get_node("ExternalHouse").player_start_position = external_house.get_node("ShopEntrance")
	EasyTransition.transition_to_node(external_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_shop() -> void:
	EasyTransition.transition_to_node(shop_room,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_cambat_zone() -> void:
	EasyTransition.transition_to_node(combat_zone,1.5,EasyTransition.TransitionAnim.FADE)
