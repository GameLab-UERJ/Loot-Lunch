extends Node

const AUTOSAVE_POSITION : int = 6
const AUTOSAVE_NAME : String = "AUTOSAVE"

var save_path: String = "user://Save/"
var SaveFileData: SaveData
var save_list: PackedStringArray
var saves_info: Array[Array]


func _ready() -> void:
	_get_save_info()


func save_data(save_position: int, save_name: String) -> void:
	if saves_info[save_position][0] != "VAZIO":
		erase_data(save_position)

	saves_info[save_position][0] = save_name
	saves_info[save_position][1] = Time.get_datetime_dict_from_system()

	GlobalData.collect_game_state()

	SaveFileData = SaveData.new()

	SaveFileData.save_name = saves_info[save_position][0]
	SaveFileData.save_time = saves_info[save_position][1]
	SaveFileData.scene_path = GlobalData.current_scene_path
	SaveFileData.player_position_x = GlobalData.player_position.x
	SaveFileData.player_position_y = GlobalData.player_position.y
	SaveFileData.inventory_items = GlobalData.inventory_data
	SaveFileData.time_state = GlobalData.time_state
	SaveFileData.time_remaining = GlobalData.time_remaining
	SaveFileData.day_night_color_r = GlobalData.day_night_color.r
	SaveFileData.day_night_color_g = GlobalData.day_night_color.g
	SaveFileData.day_night_color_b = GlobalData.day_night_color.b
	SaveFileData.quest_status = GlobalData.quest_status

	# Use .tres for testing and change to .res when in production
	ResourceSaver.save(SaveFileData, save_path + SaveFileData.save_name + ".tres")


func autosave() -> void:
	save_data(AUTOSAVE_POSITION, AUTOSAVE_NAME)


func load_data(file_name: String, apply_state: bool = false) -> void:
	if FileAccess.file_exists(save_path + file_name):
		SaveFileData = ResourceLoader.load(save_path + file_name).duplicate(true)
		GlobalData.current_scene_path = SaveFileData.scene_path
		GlobalData.player_position = Vector2(SaveFileData.player_position_x, SaveFileData.player_position_y)
		GlobalData.inventory_data = SaveFileData.inventory_items
		GlobalData.time_state = SaveFileData.time_state
		GlobalData.time_remaining = SaveFileData.time_remaining
		GlobalData.day_night_color = Color(SaveFileData.day_night_color_r, SaveFileData.day_night_color_g, SaveFileData.day_night_color_b)
		GlobalData.quest_status = SaveFileData.quest_status
		if apply_state:
			GlobalData.schedule_restore_after_load()


func load_autosave() -> void:
	load_data(AUTOSAVE_NAME + ".tres",true)


func erase_data(save_position: int) -> void:
	# Use .tres for testing and change to .res when in production
	DirAccess.open(save_path).remove(saves_info[save_position][0] + ".tres")

	saves_info[save_position][0] = "VAZIO"
	saves_info[save_position][1] = {}


# -- Store basic saves info --
func _get_save_info() -> void:
	saves_info.resize(7)

	if !DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_absolute(save_path)

	save_list = DirAccess.get_files_at(save_path)

	for i in range(7):
		saves_info[i].resize(2)

		if i < save_list.size():
			load_data(save_list[i])

			saves_info[i][0] = SaveFileData.save_name
			saves_info[i][1] = SaveFileData.save_time
		else:
			saves_info[i][0] = "VAZIO"
			saves_info[i][1] = {}
