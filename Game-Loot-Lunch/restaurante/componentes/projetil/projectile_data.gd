extends Resource
class_name ProjectileData
## DADOS de um projétil (ovo do Patolino, caveira de fogo da Mandy, esfera de raio do Johnny...).
##
## Regra de sempre: **o projétil é cena, o tipo de projétil é dado.**
## A cena `projetil.tscn` não sabe o que é um ovo: ela só lê um ProjectileData (.tres).
##
## A arte vem de UMA spritesheet em grade (quadros do mesmo tamanho). Cada parte do
## projétil (voo, sombra, impacto) aponta para uma LINHA e um intervalo de COLUNAS.
## Linhas e colunas contam a partir de 1, igual ao SpriteSheetEffect.
## `*_frame_count = 0` desliga aquela parte (ex.: projétil sem sombra).
##
## Se a arte vier em ARQUIVOS SEPARADOS (um para o voo, outro para o impacto...), preencha
## `fly_sheet`, `impact_sheet`, `spawn_sheet`: vazio = usa a `sheet` principal.
##
## Novo projétil: FileSystem > botão direito > New Resource > ProjectileData.


@export_group("Arte")
@export var sheet: Texture2D
## Tamanho de cada quadro da grade, em pixels.
@export var frame_size: Vector2i = Vector2i(16, 16)
## Escala da arte (voo, sombra e impacto).
@export var sprite_scale: Vector2 = Vector2.ONE

@export_group("Voo")
@export_range(1, 64) var fly_row: int = 1
@export_range(1, 128) var fly_first_column: int = 1
@export_range(0, 128) var fly_frame_count: int = 1
@export var fly_fps: float = 12.0
## Gira a arte para apontar na direção do voo (lança, raio). O ovo já gira na própria arte.
@export var rotate_with_direction: bool = false
## Espelha a arte quando voa para a esquerda (caveira que olha para a direita).
@export var flip_with_direction: bool = false
## Arte do voo em arquivo separado. Vazio = `sheet`.
@export var fly_sheet: Texture2D

@export_group("Surgir")
## Animação que toca PARADA na mão de quem atira, antes de sair voando. 0 quadros = sem.
@export var spawn_sheet: Texture2D
@export_range(1, 64) var spawn_row: int = 1
@export_range(1, 128) var spawn_first_column: int = 1
@export_range(0, 128) var spawn_frame_count: int = 0
@export var spawn_fps: float = 12.0
## Depois de surgir, mira de novo no alvo (onde ele está AGORA).
@export var reaim_after_spawn: bool = true

@export_group("Sombra")
## A sombra fica no chão. Com 2+ quadros, o primeiro é usado perto do chão
## e o último no ponto mais alto do arco (sombra menor).
@export_range(1, 64) var shadow_row: int = 1
@export_range(1, 128) var shadow_first_column: int = 1
@export_range(0, 128) var shadow_frame_count: int = 0
@export_range(0.0, 1.0) var shadow_opacity: float = 0.8

@export_group("Impacto")
## Toca uma vez onde o projétil bateu (no alvo, na parede ou no fim do alcance).
@export_range(1, 64) var impact_row: int = 1
@export_range(1, 128) var impact_first_column: int = 1
@export_range(0, 128) var impact_frame_count: int = 0
@export var impact_fps: float = 14.0
## Arte do impacto em arquivo separado. Vazio = `sheet`.
@export var impact_sheet: Texture2D

@export_group("Movimento")
@export var speed: float = 170.0
## Distância máxima. Se não acertar nada até aqui, estoura no chão.
@export var max_distance: float = 360.0
## Altura do "arco" do voo (só visual, em pixels). 0 = reto.
@export var arc_height: float = 6.0
## Quanto o projétil vira na direção do alvo, em graus por segundo.
## 0 = reto (ovo). Maior = teleguiado (esfera de raio que persegue).
@export var homing_turn_speed: float = 0.0

@export_group("Acerto")
## Raio de colisão do projétil.
@export var hit_radius: float = 5.0
## Dano em PONTOS de vida (2 pontos = 1 caveira inteira). Ex.: 6 = 3 caveiras.
@export var damage: int = 2
## Empurrão no alvo atingido.
@export var knockback: int = 120
## Só acerta corpos neste grupo. Vazio = qualquer corpo que tenha `take_damage`.
@export var target_group: StringName = &"chefs"
## Camadas que fazem o projétil estourar (paredes, balcão...). 1 = World.
@export_flags_2d_physics var world_mask: int = 1
## Camadas de quem pode ser atingido. 2 = Player.
@export_flags_2d_physics var target_mask: int = 2

@export_group("Lentidão ao acertar")
## 0.5 = quem for atingido anda 50% mais devagar. 0 = sem lentidão.
@export_range(0.0, 1.0) var slow_percent: float = 0.0
## Segundos de lentidão.
@export var slow_duration: float = 2.0
@export var slow_tint: Color = Color(0.85, 0.7, 1.0)


## Monta as animações "voo", "sombra" e "impacto" a partir da spritesheet.
func build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	_add_animation(frames, &"voo", _sheet_for(fly_sheet), fly_row, fly_first_column,
			fly_frame_count, fly_fps, true)
	_add_animation(frames, &"sombra", sheet, shadow_row, shadow_first_column,
			shadow_frame_count, 1.0, false)
	_add_animation(frames, &"impacto", _sheet_for(impact_sheet), impact_row, impact_first_column,
			impact_frame_count, impact_fps, false)
	_add_animation(frames, &"surgir", _sheet_for(spawn_sheet), spawn_row, spawn_first_column,
			spawn_frame_count, spawn_fps, false)
	return frames


func has_part(animation: StringName) -> bool:
	match animation:
		&"voo":
			return fly_frame_count > 0 and _sheet_for(fly_sheet) != null
		&"sombra":
			return shadow_frame_count > 0 and sheet != null
		&"impacto":
			return impact_frame_count > 0 and _sheet_for(impact_sheet) != null
		&"surgir":
			return spawn_frame_count > 0 and _sheet_for(spawn_sheet) != null
	return false


func _sheet_for(part_sheet: Texture2D) -> Texture2D:
	return part_sheet if part_sheet != null else sheet


func _add_animation(frames: SpriteFrames, animation: StringName, texture: Texture2D, row: int,
		first_column: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, loop)
	frames.set_animation_speed(animation, fps)
	if texture == null or count <= 0:
		return
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			(first_column - 1 + i) * frame_size.x,
			(row - 1) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		frames.add_frame(animation, atlas)
