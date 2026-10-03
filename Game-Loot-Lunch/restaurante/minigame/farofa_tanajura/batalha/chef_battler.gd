extends Battler
class_name ChefBattler
## O CHEF na batalha da Fase 3.
##
## Tem as mesmas peças de HUD do chef do restaurante, então o HudChef (caveiras + mana)
## funciona sem mudar nada: expõe `hp`, `max_hp` e `health_changed` (repassando do
## BattleHealthComponent) e tem um ManaComponent filho.
##
## TEMPO DE ESPERA: o BattleWaitComponent filho enche a barrinha dourada embaixo dele
## (`wait_bar`); cheia = o menu libera as habilidades.
##
## As habilidades são os filhos BattleSkill (Frigideirada, Investida Sombria, Besta,
## Devorar). Nova habilidade = novo nó filho; nada muda aqui nem no menu.
## As animações de golpe/contra-ataque são da arte "padrão da luta" (quadros 48x48 com
## o chef em (4,16)): ficam no SheetSprite "Sprite" e são chamadas por nome com `act()`.


## Mesmo sinal do Chef: o ChefHUD escuta.
signal health_changed(current: int, maximum: int)


## Ponto onde os anéis de QTE aparecem (em volta do chef).
@export var qte_anchor: Node2D
## Barrinha do tempo de espera.
@export var wait_bar: ProgressBarComponent
@export var wait_fill_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var ready_fill_color: Color = Color(0.55, 1.0, 0.45, 1.0)


# Lidos pelo ChefHUD (que pode acordar antes do chef: por isso procura o componente).
var hp: int:
	get:
		var h: BattleHealthComponent = BattleHealthComponent.find_in(self)
		return h.hp if h else 0
var max_hp: int:
	get:
		var h: BattleHealthComponent = BattleHealthComponent.find_in(self)
		return h.max_hp if h else 0


var _clock: float = 0.0


@onready var mana: ManaComponent = ManaComponent.find_in(self)
@onready var skills: Array[BattleSkill] = BattleSkill.find_all_in(self)


func _ready() -> void:
	super._ready()
	health.health_changed.connect(func(current: int, maximum: int) -> void:
		health_changed.emit(current, maximum))
	health_changed.emit(health.hp, health.max_hp)
	if wait and wait_bar:
		wait.progress_changed.connect(_on_wait_progress)
		_on_wait_progress(wait.get_ratio())


## Mostra/esconde a barrinha de espera (some fora da luta, ex.: no preparo da farofa).
func show_wait_bar(value: bool) -> void:
	if wait_bar:
		wait_bar.set_bar_visible(value)


func _process(delta: float) -> void:
	# Barra cheia pisca de leve: "sua vez!".
	if wait_bar and wait and wait.is_ready() and wait_bar.visible:
		_clock += delta
		wait_bar.modulate.a = 0.65 + 0.35 * sin(_clock * 10.0)
	elif wait_bar:
		wait_bar.modulate.a = 1.0


func _on_wait_progress(ratio: float) -> void:
	wait_bar.set_progress(ratio)
	wait_bar.fill_color = ready_fill_color if ratio >= 1.0 else wait_fill_color
	wait_bar.queue_redraw()
