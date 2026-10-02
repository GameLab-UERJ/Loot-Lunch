extends Battler
class_name ChefBattler
## O CHEF na batalha por turnos da Fase 3.
##
## Tem as mesmas peças de HUD do chef do restaurante, então o HudChef (caveiras + mana)
## funciona sem mudar nada: expõe `hp`, `max_hp` e `health_changed` (repassando do
## BattleHealthComponent) e tem um ManaComponent filho.
##
## As habilidades são os filhos BattleSkill (Frigideirada, Investida Sombria, Bolo de
## Fogo, Devorar). Nova habilidade = novo nó filho; nada muda aqui nem no menu.


## Mesmo sinal do Chef: o ChefHUD escuta.
signal health_changed(current: int, maximum: int)


## Sprite da frigideira (aparece nos golpes e nos contra-ataques).
@export var frying_pan: Node2D
## Ponto onde os anéis de QTE aparecem (em volta do chef).
@export var qte_anchor: Node2D


# Lidos pelo ChefHUD (que pode acordar antes do chef: por isso procura o componente).
var hp: int:
	get:
		var h: BattleHealthComponent = BattleHealthComponent.find_in(self)
		return h.hp if h else 0
var max_hp: int:
	get:
		var h: BattleHealthComponent = BattleHealthComponent.find_in(self)
		return h.max_hp if h else 0


@onready var mana: ManaComponent = ManaComponent.find_in(self)
@onready var skills: Array[BattleSkill] = BattleSkill.find_all_in(self)


func _ready() -> void:
	super._ready()
	health.health_changed.connect(func(current: int, maximum: int) -> void:
		health_changed.emit(current, maximum))
	health_changed.emit(health.hp, health.max_hp)
	if frying_pan:
		frying_pan.hide()


## Frigideirada visual (golpe, contra-ataque, rebater pedra). Não dá dano: só a animação.
func swing_pan(toward: Vector2 = Vector2.RIGHT) -> void:
	if frying_pan == null:
		return
	frying_pan.show()
	var side: float = signf(toward.x) if not is_zero_approx(toward.x) else 1.0
	frying_pan.position = Vector2(10.0 * side, -6.0)
	frying_pan.scale = Vector2(side, 1.0) * absf(frying_pan.scale.y)
	frying_pan.rotation = deg_to_rad(-100.0) * side
	var tween := create_tween()
	tween.tween_property(frying_pan, "rotation", deg_to_rad(40.0) * side, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.12)
	tween.tween_callback(frying_pan.hide)
	await tween.finished
