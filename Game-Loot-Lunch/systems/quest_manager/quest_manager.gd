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
	ENTREGAR_A_JULIETA
}

var current_status: QuestStatus = QuestStatus.NAO_INICIADA

func get_mission_text(quest : QuestStatus) -> String:
	var mission_text: String = ""
	match quest:
		QuestManager.QuestStatus.NAO_INICIADA:
			mission_text = "Objetivo: Fale com Carlos - O Guia na casa."
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
			mission_text = "Objetivo: Pegue Saco de Sal de Olhos Voadores na zona depois da ponte."
		QuestManager.QuestStatus.SALGAR_CARNE:
			mission_text = "Objetivo: Na Mesa Simples, Misture a Carne com o Sal."
		QuestManager.QuestStatus.SECAR_CARNE:
			mission_text = "Objetivo: Coloque a Carne para secar no Varal."
		QuestManager.QuestStatus.PEGAR_INGREDIENTES_VINAGRETE:
			mission_text = "Objetivo: Na Horta, pegue Tomate, Cebola e Pimentao"
		QuestManager.QuestStatus.CORTAR_INGREDIENTES_VINAGRETE:
			mission_text = "Objetivo: Na Mesa de Corte, corte o Tomate, a Cebola e o Pimentao"
		QuestManager.QuestStatus.FAZER_VINAGRETE:
			mission_text = "Objetivo: Na Mesa Simples, misture o Tomate, a Cebola e o Pimentao para fazer o Vinagrete"
		QuestManager.QuestStatus.FAZER_REFEICAO_FINAL:
			mission_text = "Objetivo: Na Mesa Simples, misture os 3 pratos em um."
		QuestManager.QuestStatus.ENTREGAR_A_JULIETA:
			mission_text = "Objetivo: Leve a Carne de Sol com Farofa de Tanajura e Vinagrete para Julieta na Masmorra."
		_:
			mission_text = "NÃO DEFINIDA. CHECAR quest_manager.gd"
	
	return mission_text


func advance_mission(new_stage: QuestStatus) -> void:
	current_status = new_stage
	mission_updated.emit(current_status)
