extends Node

var save_path: String = "user://Save/"
var SaveFileData: SaveData

var save_list: PackedStringArray
var saves_info: Array[Array]


func _ready() -> void:
	_get_save_info()


func save_data(save_position: int, save_name: String) -> void:
	if saves_info[save_position][0] != "VAZIO":
		erase_data(save_position)
	
	# Data used in save slots from SaveLoadMenu
	saves_info[save_position][0] = save_name
	saves_info[save_position][1] = Time.get_datetime_dict_from_system()
	
	SaveFileData = SaveData.new()
	
	# Data to save in memory
	SaveFileData.save_name = saves_info[save_position][0]
	SaveFileData.save_time = saves_info[save_position][1]
	
	# Use .tres for testing and change to .res when in production
	ResourceSaver.save(SaveFileData, save_path + SaveFileData.save_name + ".tres")


func load_data(file_name: String) -> void:
	if FileAccess.file_exists(save_path + file_name):
		SaveFileData = ResourceLoader.load(save_path + file_name).duplicate(true)


func erase_data(save_position: int) -> void:
	# Use .tres for testing and change to .res when in production
	DirAccess.open(save_path).remove(saves_info[save_position][0] + ".tres")
	
	saves_info[save_position][0] = "VAZIO"
	saves_info[save_position][1] = {}


# -- Store basic saves info --
func _get_save_info() -> void:
	saves_info.resize(6)

	if !DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_absolute(save_path)
	
	save_list = DirAccess.get_files_at(save_path)
	
	for i in range(6):
		saves_info[i].resize(2)
		
		if i < save_list.size():
			load_data(save_list[i])
			
			saves_info[i][0] = SaveFileData.save_name
			saves_info[i][1] = SaveFileData.save_time
		else:
			saves_info[i][0] = "VAZIO"
			saves_info[i][1] = {}
