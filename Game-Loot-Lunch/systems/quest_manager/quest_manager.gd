extends Node

signal mission_updated(new_stage: QuestStatus)

enum QuestStatus {
	NAO_INICIADA,
	PROCURAR_INGREDIENTES,
	PREPARAR_PRATO,
	CONCLUIDA
}

var current_status: QuestStatus = QuestStatus.NAO_INICIADA

func advance_mission(new_stage: QuestStatus) -> void:
	current_status = new_stage
	mission_updated.emit(current_status)
