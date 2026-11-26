# Brasa — a churrasqueira que é uma chama viva (2º jogador)

A Brasa faz **tudo** que a churrasqueira faz (assar cru → no ponto → torrado → queima, devolver no ponto em que estiver, R para descartar, voltar para o fogo, labareda aleatória), mas **anda**: é o 2º jogador no mesmo teclado.

## Como foi montada (reaproveitando o que já existia)

A Brasa é um `Character` (como o chef) que **carrega uma `CookingStation` de verdade** como filha. Nenhum script da churrasqueira foi alterado.

```
Brasa (CharacterBody2D, script Brasa extends Character)   layer 2, mask 33 (paredes + balcão)
├── FiniteStateMachine     BrasaFSM — lê as setas e escolhe a animação
├── AnimatedSprite2D       brasa_frames.tres (48x48), position (0,-6)
├── CollisionShape2D       círculo raio 9 em (0,6)
├── AnimationPlayer        vazio (a FiniteStateMachine base exige)
├── InputComponent         ActionInputComponent: brasa_up/down/left/right (setas)
├── MovementComponent      o mesmo do chef
└── Churrasqueira          CookingStation (o MESMO script da churrasqueira), layer 0
    ├── InteractableComponent   Area2D 56x46, highlight = sprite da Brasa
    ├── Bocas
    │   ├── BocaDireita   CookingSlot em (17, 9)  -> Mao, Girando, Barra, Balao, Efeito
    │   └── BocaEsquerda  CookingSlot em (-17, 9)
    └── FlameRandomEvent  a mesma labareda aleatória da churrasqueira
```

Os espetinhos ficam nas "mãos" de fogo, dos dois lados da chama, e andam junto com ela.

## Componente novo (único)

`entities/base_classes/components/action_input_component.gd` — `ActionInputComponent extends InputComponent`.
O `InputComponent` original lê sempre `ui_*` (WASD **e** setas juntos), então com 2 jogadores as setas mexeriam os dois. Este é igual, mas cada um lê as ações escolhidas no Inspector. Padrão = `ui_*` (trocar o script não muda nada até preencher outras ações).

## Teclas (Input Map, ações novas)

| Ação | Tecla | Quem usa |
|---|---|---|
| `brasa_up/down/left/right` | setas | Brasa |
| `chef_up/down/left/right` | W S A D | chef no modo 2 jogadores |

O `chef.tscn` **não mudou** (continua com WASD + setas). Na cena de 2 jogadores, o nó `InputComponent` do chef recebe o script `ActionInputComponent` com as ações `chef_*` (sobrescrito só na cena, igual em `teste_brasa.tscn`).

## Animações (`assets/art/restaurant/comidas/utensilios/brasa/`)

Tiras de quadros 48x48 (mesmo formato das `churrasqueira_*.png`). `brasa_frames.tres` junta todas.

| Animação | Quadros | fps | Quando |
|---|---|---|---|
| `surgir` | 8 | 12 | ao entrar na cena (brasinha no chão vira chama), uma vez |
| `idle` | 8 | 8 | parada e sem espetinho (pisca no quadro 6) |
| `andar` | 8 | 12 | andando: inclina, pulinho, rastro de fagulhas (desenhada para a direita, espelha sozinha) |
| `assando` | 8 | 10 | parada com espetinho: chama maior e feliz |
| `alerta` | 8 | 14 | algum espetinho TORRADO (vale andando também): vermelha, assustada, treme |
| `risada` | 10 | 12 | um espetinho queimou e sumiu, uma vez |

Prioridade: surgir/risada vão até o fim > alerta > andar > assando > idle.

## Ajustes (Inspector)

- **Velocidade:** `max_speed` (90) e `acceleration` (30) no nó `Brasa`. O chef usa 100.
- **Tempos de cozimento:** `perfect_time` / `burnt_time` / `vanish_time` no nó `Churrasqueira` (7 / 17 / 27, iguais aos da churrasqueira da fase 1).
- **Sem 2º jogador:** `can_control = false` deixa ela parada (para IA ou cutscene).
- **Sem animação de surgir:** `play_intro = false`.
- **Teclas:** as ações no nó `InputComponent`.
- **Sem labareda aleatória:** apague o nó `Churrasqueira/FlameRandomEvent`.
- **Onde os espetinhos ficam:** `BocaDireita.position` / `BocaEsquerda.position`.
- **Mais bocas:** duplique uma boca dentro de `Bocas` (igual à churrasqueira).
- **Trocar a arte:** troque as tiras PNG (48x48 por quadro) e rode de novo o gerador do `brasa_frames.tres`, ou edite as animações no painel SpriteFrames.

## Observações

- O chef **atravessa** a Brasa (a máscara do chef não inclui a camada 2). Ela não atravessa paredes (camada 1) nem o balcão (camada 6).
- As magias dos clientes procuram o grupo `chefs`; a Brasa está no grupo `brasas` e hoje não é alvo de magia. Se for atordoada ou confundida por alguma magia futura, ela já respeita `StunComponent` e `ConfusionComponent`.

## Cena de teste `teste_brasa.tscn`

Chef + Brasa + caixa de carne + pé de cogumelo + tábua + raiz de espeto + lixeira, com paredes.
Chef: WASD anda · ESPAÇO faz tudo · Shift dash · R descarta. Brasa: setas.
Atalhos: **G** espetinho misto cru na mão do chef · **T** carne no ponto · **Y** cogumelo torrado. O canto superior direito mostra o estado da Brasa e de cada boca.
