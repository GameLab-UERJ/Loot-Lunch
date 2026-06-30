extends Node2D


var combat_zone : Node2D
var dungeon_exterior : Node2D
var internal_dungeon : Node2D
var dungeon_way : Node2D

# Prelaod PauseMenu
var pause_menu_scene: PackedScene = preload("uid://dng6eim1kbmhh")
var pause_menu: PauseMenu

@onready var inside_house: Node2D = get_node("InsideHouse") if self.has_node("InsideHouse") else null
@onready var external_house: Node2D = get_node("ExternalHouse") if self.has_node("ExternalHouse") else null
@onready var shop_room: Node2D = get_node("ShopRoom") if self.has_node("ShopRoom") else null
@onready var music_stream_player: AudioStreamPlayer = get_node("MusicStreamPlayer") if has_node("MusicStreamPlayer") else null
@onready var audio_stream_player: AudioStreamPlayer = get_node("AudioStreamPlayer") if has_node("AudioStreamPlayer") else null


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
	if not dungeon_exterior:
		dungeon_exterior = load("uid://b4stndwimfym0").instantiate()
	if not internal_dungeon:
		internal_dungeon = load("uid://y2eqacu6sy16").instantiate()
	if not dungeon_way:
		dungeon_way = load("uid://y2eqacu6sy16").instantiate()
	
	pause_game_menu()


func _on_player_can_leave_house() -> void:
	_on_change_scene()
	external_house.get_node("ExternalHouse").player_start_position = external_house.get_node("HouseEntrance")
	EasyTransition.transition_to_node(external_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_house() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(inside_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_leave_shop() -> void:
	_on_change_scene()
	external_house.get_node("ExternalHouse").player_start_position = external_house.get_node("ShopEntrance")
	EasyTransition.transition_to_node(external_house,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_shop() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(shop_room,1.5,EasyTransition.TransitionAnim.FADE)


func _on_player_can_enter_cambat_zone() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(combat_zone,1.5,EasyTransition.TransitionAnim.FADE)

func _on_player_can_enter_dungeon_exterior() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(dungeon_exterior, 1.5, EasyTransition.TransitionAnim.FADE)

func _on_player_can_enter_internal_dungeon() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(internal_dungeon, 1.5, EasyTransition.TransitionAnim.FADE)

func _on_player_can_leave_internal_dungeon() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(dungeon_exterior, 1.5, EasyTransition.TransitionAnim.FADE)

func _on_player_can_enter_dungeon_way() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(dungeon_way, 1.5, EasyTransition.TransitionAnim.FADE)

func _on_player_can_leave_dungeon_way() -> void:
	_on_change_scene()
	EasyTransition.transition_to_node(dungeon_exterior, 1.5, EasyTransition.TransitionAnim.FADE)
	

func pause_game_menu() -> void:
	if !get_parent().has_node("PauseMenu"):
		pause_menu = pause_menu_scene.instantiate() as PauseMenu
		call_deferred("add_sibling", pause_menu)

func _on_change_scene(duration : float = 1.5) -> void:
	if music_stream_player:
		create_tween().tween_property(music_stream_player,"volume_db",-30,duration)
