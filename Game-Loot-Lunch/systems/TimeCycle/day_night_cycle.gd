extends CanvasModulate


@export var transition_duration: float = 2.0


@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color(0.35, 0.4, 0.6)


@onready var _day_ambient: AudioStreamPlayer = $DayAmbient
@onready var _night_ambient: AudioStreamPlayer = $NightAmbient


var _target_color: Color

var _day_target_volume: float = 0.0
var _night_target_volume: float = -40.0


func _ready() -> void:
	TimeCycle.day_started.connect(_on_day_started)
	TimeCycle.night_started.connect(_on_night_started)

	_target_color = color

	_day_ambient.play()
	_night_ambient.play()


func _process(delta: float) -> void:
	var weight: float = delta / transition_duration

	color = color.lerp(_target_color, weight)

	_day_ambient.volume_db = move_toward(
		_day_ambient.volume_db,
		_day_target_volume,
		40.0 * weight
	)

	_night_ambient.volume_db = move_toward(
		_night_ambient.volume_db,
		_night_target_volume,
		40.0 * weight
	)


func _on_day_started() -> void:
	_target_color = day_color

	_day_target_volume = 0.0
	_night_target_volume = -40.0


func _on_night_started() -> void:
	_target_color = night_color

	_day_target_volume = -40.0
	_night_target_volume = 0.0
