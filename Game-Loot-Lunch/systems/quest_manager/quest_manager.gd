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

func get_mission_text(quest : QuestStatus) -> String:
	var mission_text: String = ""
	match quest:
		QuestManager.QuestStatus.NAO_INICIADA:
			mission_text = "Objetivo: Fale com o Guide Man na casa."
		QuestManager.QuestStatus.COMPRAR_FARINHA:
			mission_text = "Objetivo: Encontre a loja a Oeste da Casa e compre Farinha"
		QuestManager.QuestStatus.TORRAR_FARINHA:
			mission_text = "Objetivo: Encontre o Forno ao lado da Casa e torre a Farinha"
		QuestManager.QuestStatus.MATAR_TANAJURA:
			mission_text = "Objetivo: Pegue um corpo de Tanajura."
		QuestManager.QuestStatus.CORTAR_TANAJURA:
			mission_text = "Objetivo: Encontre a Mesa de Corte e corte a parte traseira da Tanajura"
		QuestManager.QuestStatus.FAZER_FAROFA:
			mission_text = "Objetivo: Na Mesa Simples, Misture a Farinha Torrada com a Tanajura Preparada"
		QuestManager.QuestStatus.MATAR_BOVINO:
			mission_text = "Objetivo: Pegue carne de um Monstro Bovino ou compre na Loja"
		QuestManager.QuestStatus.MATAR_OLHOS:
			mission_text = "Objetivo: Pegue três sacos de sal de Olhos Voadores na região após a ponte."
		_:
			mission_text = "NÃO DEFINIDA. CHECAR pause_menu.gd"
	
	return mission_text


func advance_mission(new_stage: QuestStatus) -> void:
	current_status = new_stage
	mission_updated.emit(current_status)
