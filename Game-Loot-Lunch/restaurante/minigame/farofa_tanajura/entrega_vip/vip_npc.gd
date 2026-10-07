extends StaticBody2D
class_name VipNpc
## O CLIENTE VIP que recebe o prato no fim da boss fight.
##
## A arte vem de `idle_sheet_path` (tira de quadros quadrados, padrão jscoutinho:
## jscoutinho_idle_VIP_34F.png). Enquanto o arquivo não existir no projeto, usa
## `fallback_texture` tingida de dourado e avisa no Output — assim a cena roda hoje e
## fica certa sozinha quando a arte chegar (é só soltar o PNG no caminho).
##
## Recebe a entrega pelo DeliveryReceiverComponent do restaurante (ESPAÇO com o prato na
## mão, de frente para ele) e repassa em `dish_received`.


signal dish_received(data: ItemData, deliverer: Node)


@export_file("*.png") var idle_sheet_path: String = \
	"res://restaurante/minigame/farofa_tanajura/art/Entities/NPC/vip-m/idle/jscoutinho_idle_VIP_34F.png"
## Tamanho de cada quadro. (0, 0) = quadros quadrados do tamanho da altura da imagem.
@export var frame_size: Vector2i = Vector2i.ZERO
@export var fps: float = 5.0
## A arte jscoutinho olha para a DIREITA; o VIP fica à direita da sala olhando o chef.
@export var look_left: bool = true

@export_group("Sem a arte do VIP")
@export var fallback_texture: Texture2D
@export var fallback_tint: Color = Color(1.0, 0.85, 0.45)
## Escala da arte provisória (os esqueletos dos clientes são 64x64 e usam 0.5).
@export var fallback_scale: Vector2 = Vector2(0.5, 0.5)


@onready var sprite: AnimatedSprite2D = $Sprite
@onready var receiver: DeliveryReceiverComponent = $DeliveryReceiverComponent


func _ready() -> void:
	_build_sprite()
	receiver.item_received.connect(func(data: ItemData, deliverer: Node) -> void:
		dish_received.emit(data, deliverer))


## Comemoração ao receber o prato.
func celebrate() -> void:
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -44), "MAGNÍFICO!", Color(1.0, 0.85, 0.3))
	var tween := create_tween()
	for i in 3:
		tween.tween_property(sprite, "position:y", -10.0, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)


func say(text: String) -> void:
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), text, Color(1.0, 0.95, 0.8))


func _build_sprite() -> void:
	var texture: Texture2D = null
	if idle_sheet_path != "" and ResourceLoader.exists(idle_sheet_path):
		texture = load(idle_sheet_path) as Texture2D
	if texture == null:
		push_warning("VipNpc: arte do VIP não encontrada em '%s'. Usando a provisória." % idle_sheet_path)
		texture = fallback_texture
		sprite.modulate = fallback_tint
		sprite.scale = fallback_scale
	if texture == null:
		return
	var anim := SheetAnimation.new()
	anim.texture = texture
	anim.frame_size = frame_size if frame_size != Vector2i.ZERO \
		else Vector2i(texture.get_height(), texture.get_height())
	anim.fps = fps
	anim.loop = true
	sprite.sprite_frames = anim.build_frames(&"idle")
	sprite.flip_h = look_left
	sprite.play(&"idle")
