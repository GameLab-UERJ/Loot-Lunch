# Fase 1-2 — Clareira das Teias (morcegos + panela)

Cena: `levels/restaurant/reino_caveira/fase_1_2/fase_1_2.tscn` (F6 testa sozinha). No mapa Reino Caveira, a bandeira 1-2 abre esta fase (liberada quando a 1-1 tem 1 estrela ou mais).

## Como é

Igual à 1-1 (campo com muro de fogo, 10 clientes pelos 4 lados, só cogumelo, raiva pura, relógio para frente), mais:

- **Morcegos** entram voando pelas bordas da tela e atacam o chef.
- O chef ganha a **panela**: **F** saca, **clique** bate na direção do mouse. Uma panelada mata um morcego.
- A **Brasa queima** morcego só de encostar nela.
- Teias nos cantos e aranhas penduradas no lugar dos morcegos de enfeite da 1-1 (para não confundir com os de verdade).

## Morcego (`entities/enemies/morcego/`)

| Estado | O que faz |
|---|---|
| entrar | vem da borda da tela até a arena |
| rondar | circula em volta do chef mais próximo (2,2 a 4 s) |
| mirar | **para no ar, treme e fica de cara brava**: é o aviso do ataque (0,45 s) |
| mergulho | dispara em linha reta para onde o chef estava (0,6 s) |
| recuar | foge um pouco e volta a rondar |
| dano | levou golpe: empurrão + pisca branco |
| morrer | vira fumaça e some |
| fugir | fim da fase: sai voando da tela |

- Vida `hp` = 2. Mordida = 1 de dano (meia caveira), só no chef (a Brasa é fogo).
- Voa por cima de tudo (máscara 0) e fica preso dentro de `arena` depois de entrar.
- Ajustes no `morcego.tscn` (nó raiz): `cruise_speed`, `dive_speed`, `orbit_radius`, `orbit_time_min/max`, `telegraph_time`, `dive_time`, `retreat_time`.
- Arte: `assets/art/restaurant/inimigos/morcego/morcego.png` (13 quadros de 26x22). Animações em `morcego_frames.tres`: `voar` (0–3), `mergulho` (4–5), `dano` (6–7), `morrer` (8–12).

## Panela (`entities/player/chef/armas/panela.tscn` + `habilidades/panela_ability.gd`)

Combate igual ao do jogo normal com a espada: a panela sacada aponta para o **mouse** e o **clique** bate (`ui_attack`, a mesma ação do Player). Por dentro é a mesma dinâmica: um nó que gira para a mira e espelha à esquerda, um `HitboxComponent` que só liga durante a animação `golpe` do `AnimationPlayer` e o rastro do golpe.

| Situação | O que acontece |
|---|---|
| **F** com a mão vazia | saca a panela (ela aparece na mão, apontando para o mouse) |
| **F** segurando um item | o item **cai no chão** e a panela aparece na mão |
| **F** com a panela sacada | guarda a panela |
| **Clique** com a panela sacada | panelada na direção do mouse |
| Pegou um item (chão, pé de cogumelo, estação...) | a panela é **guardada** sozinha |
| Chef caiu | a panela é guardada |

Com a panela sacada, o chef olha para o mouse (como o Player). Isso inclui o ESPAÇO, que usa o que estiver do lado da mira. Não gasta mana.

- No `chef.tscn`: nós `Panela` e `HabilidadePanela` (ação `chef_attack` = F para sacar/guardar; `attack_action` = `ui_attack` para bater). Na 1-1 ela fica desligada (`enabled = false`), como as outras habilidades.
- Sem mouse: `HabilidadePanela.aim_with_mouse = false` faz bater para onde o chef olha (WASD).
- Dano e empurrão: `Panela/HitboxComponent` → `damage` (2), `knockback_force` (260). Tamanho do acerto: o círculo do `CollisionShape2D`.
- Tempo entre golpes: `HabilidadePanela.cooldown`. Pose parada e giro do golpe: animações `RESET` e `golpe` da `panela.tscn`.
- Arte: `assets/art/restaurant/armas/panela/panela.png` e `panela_golpe.png` (rastro, 3 quadros de 32x32).

## Brasa queima

`brasa.tscn` ganhou o nó `Queimadura` (`HitboxComponent`, máscara 4 = inimigos, grupo `inimigos`): 1 de dano a cada 0,5 s encostado e empurra o morcego para longe dela. Vale em qualquer fase com Brasa.

## Quantos morcegos (nó `Morcegos`, `BatSpawner`)

| Export | Valor | O que é |
|---|---|---|
| `first_delay` | 10 s | o 1º morcego, depois que o relógio anda |
| `interval_min/max` | 7–12 s | entre um e outro |
| `max_alive` | 2 | vivos ao mesmo tempo |
| `ramp_after` / `max_alive_late` | 120 s / 3 | depois de 2 min, até 3 vivos |
| `total` | 0 | sem limite na fase |
| `arena` | (56,56) 528x256 | onde eles voam |

O spawner começa sozinho com o relógio (`level_started`) e, no fim da fase, manda os vivos embora. Serve para qualquer outra fase: arraste o nó, aponte `level`, `container` e `enemy_scene`.

## Mudanças em arquivos que já existiam

- `systems/hitbox/hitbox_component.gd`: acompanha **cada corpo** separado (antes, um segundo alvo saindo da área parava o dano do primeiro) e ganhou `repeat_time`, `target_group` e `knockback_from_center`. Os padrões mantêm o comportamento antigo da espada, do olho voador e dos espinhos.
- `chef.tscn`: `Panela` + `HabilidadePanela`.
- `brasa.tscn`: `Queimadura`.
- `project.godot`: ação `chef_attack` (F).
- `fase_1_1.tscn`: panela desligada.
- `reino_caveira.tscn`: bandeira 1-2 aponta para esta cena.

Nesta cena o chef usa máscara 33 (paredes + muro de fogo). Sem a camada 3, ele passa por baixo dos morcegos em vez de trombar neles.
