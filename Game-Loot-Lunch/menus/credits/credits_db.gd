extends Node
class_name  CredidsDB

const categories: Dictionary = {
	# 'função': 'título do grupo'
	'coordenador': 'Coordenacao',
	'identidade_visual': 'Identidade Visual',
	'programador': 'Programacao',
	'game_designer': 'Game Design',
	'level_design': 'Level Design',
	'artista': 'Arte',
	'ui': 'Interface com Usuario',
	'som_designer': 'Sound Design',
	'inventario': 'Desenvolvimento - Inventario',
	'crafting': 'Desenvolvimento - Crafting',
	'tempo': 'Desenvolvimento - Passagem de Tempo',
	'missões': 'Desenvolvimento - Quests',
	'combate': 'Desenvolvimento - Combate',
	'loja': 'Desenvolvimento - Loja',
	'save_load': 'Desenvolvimento - Save/Load',
	'player': 'Desenvolvimento - Player',
	'voador': 'Desenvolvimento - Olho Voador',
	'tanajura': 'Desenvolvimento - Tanajura',
	'bovino': 'Desenvolvimento - Monstro Bovino',
	'masmorra': 'Desenvolvimento - Masmorra',
	'npcs': 'Desenvolvimento - NPCs',
	'dialogos': 'Desenvolvimento - Dialogos',
	'workbench': 'Desenvolvimento - Mesas de Crafting',
}

const equip_credits: Dictionary = {
		'Gabriel Carvalho': {
			'role': ['coordenador', 'programador', 'artista', 'som_designer', 'ui', 
			'inventario', 'missões','combate','bovino','npcs','dialogos','workbench'],
			'issues_done': []
		},
		'Igor Amaral': {
			'role': ['coordenador', 'programador', 'artista', 'ui', 'level_design', 'inventario', 'loja','save_load'],
			'issues_done': []
		},
		'Felipe Mello': {
			'role': ['programador', 'artista', 'level_design', 'crafting','masmorra','npcs'],
			'issues_done': []
		},
		'Douglas Carvalho': {
			'role': ['programador', 'artista', 'ui', 'level_design', 'combate','save_load','tanajura'],
			'issues_done': []
		},
		'Joao Pedro Lomba': {
			'role': ['programador', 'ui', 'tempo','npcs','dialogos'],
			'issues_done': []
		},
		'Breno Santana': {
			'role': ['programador', 'missões','npcs','dialogos'],
			'issues_done': []
		},
		'Ramon Lima': {
			'role': ['programador', 'game_designer', 'artista', 'player', 'combate','voador'],
			'issues_done': []
		},
		'Guilherme Linhares': {
			'role': ['game_designer'],
			'issues_done': []
		},
		'Rebeca Ferreira': {
			'role': ['programador', 'level_design', 'ui'],
			'issues_done': []
		},
		'Thiago Almeida':  {
			'role': ['artista','workbench'],
			'issues_done': []
		},
		'Marcos Rodrigues': {
			'role': ['identidade_visual'],
			'issues_done': []
		},
	}

const assets_credits: Dictionary = {
	# 'autor': {'file_name': 'link'}
}
