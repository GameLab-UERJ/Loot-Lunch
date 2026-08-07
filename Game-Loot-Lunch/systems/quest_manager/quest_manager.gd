extends Node

signal mission_updated(new_stage: QuestStatus)

enum QuestStatus {
	NAO_INICIADA,
	COMPRAR_FARINHA,
	TORRAR_FARINHA,
	MATAR_TANAJURA,
	CORTAR_TANAJURA,
	FAZER_FAROFA,
	MATAR_BOVINO,
	MATAR_OLHOS,
	SALGAR_CARNE,
	SECAR_CARNE,
	PEGAR_INGREDIENTES_VINAGRETE,
	CORTAR_INGREDIENTES_VINAGRETE,
	FAZER_VINAGRETE,
	FAZER_REFEICAO_FINAL,
	ENTREGAR_AO_GUIA,
	ENTREGAR_A_JULIETA
}

var current_status: QuestStatus = QuestStatus.NAO_INICIADA

func advance_mission(new_stage: QuestStatus) -> void:
	current_status = new_stage
	mission_updated.emit(current_status)
