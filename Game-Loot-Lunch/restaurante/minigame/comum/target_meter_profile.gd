extends Resource
class_name TargetMeterProfile
## DADO de um medidor "acerte o ponto": a carne no Mini-Sol, o cozimento da macaxeira,
## a dose de manteiga... Quem mede é o TargetMeterComponent; quem desenha é o TimingGauge.
##
## Mesma regra do resto do projeto: **a etapa é cena, a dificuldade é dado.**
## Ponto mais difícil = outro .tres (Botão direito > New Resource > TargetMeterProfile).
##
## A barra vai de 0.0 a 1.0 e tem 3 zonas:
##     0 ........ perfect_min ===== perfect_max ........ 1
##        ANTES (cru/suado)    PONTO       DEPOIS (carbonizado/encharcado)


enum Zone { UNDER, PERFECT, OVER }


@export var display_name: String = "Ponto"

@export_group("Velocidade")
## Quanto a barra sobe por segundo enquanto está ATIVA (segurando a tecla, no fogo...).
@export_range(0.0, 2.0, 0.01) var rise_speed: float = 0.25
## Soma na velocidade a cada segundo ativo (começa calmo e vai apertando).
@export_range(0.0, 2.0, 0.01) var rise_acceleration: float = 0.0
## Quanto a barra desce por segundo enquanto INATIVA (esfriando). 0 = fica parada.
@export_range(0.0, 2.0, 0.01) var fall_speed: float = 0.0
## Variação da velocidade (0 = constante, 0.5 = oscila entre 50% e 150%). Ritmo irregular
## obriga o jogador a OLHAR a barra em vez de contar o tempo.
@export_range(0.0, 1.0, 0.01) var wobble: float = 0.0
@export var wobble_frequency: float = 2.0

@export_group("Zonas")
@export_range(0.0, 1.0, 0.01) var perfect_min: float = 0.68
@export_range(0.0, 1.0, 0.01) var perfect_max: float = 0.82
## Chegou aqui = estragou NA HORA (não espera soltar). 1.0 = só no fim da barra.
@export_range(0.0, 1.0, 0.01) var ruin_at: float = 1.0
## Soltar abaixo disto não conta como "tirar do fogo" (é só uma pausa para respirar).
@export_range(0.0, 1.0, 0.01) var min_commit: float = 0.0

@export_group("Nomes do resultado")
@export var under_label: String = "Crua"
@export var perfect_label: String = "Perfeita"
@export var over_label: String = "Passou do ponto"


func zone_of(value: float) -> Zone:
	if value < perfect_min:
		return Zone.UNDER
	if value <= perfect_max:
		return Zone.PERFECT
	return Zone.OVER


func label_of(value: float) -> String:
	match zone_of(value):
		Zone.UNDER:
			return under_label
		Zone.PERFECT:
			return perfect_label
	return over_label


## 1.0 = no centro exato da zona perfeita; cai até 0.4 na borda; 0 fora dela.
func quality_of(value: float) -> float:
	if zone_of(value) != Zone.PERFECT:
		return 0.0
	var center: float = (perfect_min + perfect_max) * 0.5
	var half: float = maxf((perfect_max - perfect_min) * 0.5, 0.001)
	return lerpf(1.0, 0.4, clampf(absf(value - center) / half, 0.0, 1.0))
