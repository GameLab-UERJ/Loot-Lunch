# Fase 1-1 — Portão de Ossos (campo aberto + muro de fogo)

Cena: `levels/restaurant/reino_caveira/fase_1_1/fase_1_1.tscn` (F6 testa sozinha). No mapa Reino Caveira, a bandeira 1-1 abre esta fase.

## Como é

- Mesmas dimensões da primeira cozinha (640x360), mas é um **campo aberto** do Reino Caveira.
- A **Brasa acende um muro de fogo** em volta do campo no começo da fase. O chef e a Brasa ficam dentro; os clientes não entram.
- **20 clientes** (Johnny, Mandy e Patolino) chegam pelos **4 lados**, até 3 por lado: em cima, embaixo, à esquerda e à direita.
- Cada cliente fica **travado no fogo lançando magia até ser atendido**. A paciência acabou? Ele não vai embora: fica bravo ("Grrr!"), a barra recomeça um pouco menor e ele volta a lançar magia.
- A entrega é por cima do muro: chegue na beirada do fogo de frente para o cliente e aperte ESPAÇO.
- **Só cogumelo** nesta fase: os pedidos são espetinho de cogumelo, no ponto ou torrado.
- O **relógio anda para frente** e cronometra quanto tempo vocês levam para atender os 20.

## Estrelas (no `fase_1_1.tres`)

| Estrelas | Pedidos certos | Tempo |
|---|---|---|
| ★ | 10 ou mais | qualquer (é o mínimo para passar) |
| ★★ | 15 ou mais | até 10:00 |
| ★★★ | 18 ou mais | até 7:30 |

Os números ficam em `star_min_correct` e `star_max_time` (0 = sem limite). O placar mostra a melhor estrela que ainda dá para pegar, e muda quando o tempo passa do limite ou faltam clientes para chegar nos certos.

O resultado fica guardado durante a sessão: a bandeira 1-1 do mapa mostra as estrelas e a 1-2 é liberada quando a 1-1 tem pelo menos 1 estrela.

## Controles

| Quem | Tecla | O que faz |
|---|---|---|
| Chef | WASD | anda |
| Chef | ESPAÇO | pega / colhe / corta / usa / entrega |
| Chef | R | joga fora |
| Chef | **Q (segurar)** | **conjura e planta um pé de cogumelo** à frente (máximo 3: o mais velho murcha) |
| Chef | **E (segurar)** | **conjura e planta uma raiz de gravetos** para montar o espeto (máximo 2) |
| Brasa | setas | anda (é a churrasqueira) |

O Shift (dash) e as habilidades antigas (arremesso e sombra) estão **desligados nesta fase**. A ideia é o jogador ganhar essas habilidades com o tempo.

**Fluxo:** Q planta → ESPAÇO colhe o cogumelo → tábua (ESPAÇO x5) → raiz de gravetos (2 cogumelos cortados) → espetinho cru → Brasa (assa) → cliente.

Se o chef cair, ele volta depois de 3 s com a vida cheia (`revive_delay`). Só perde tempo, porque `fail_on_chef_death` está desligado no `.tres`.

## Scripts novos

| Arquivo | O que é |
|---|---|
| `levels/restaurant/stopwatch_level.gd` (`StopwatchLevel`) | Fase com cronômetro: acende o muro, liga o diretor, conta o tempo, decide as estrelas, guarda o resultado no mapa, "Jogar de novo" / "Voltar ao mapa". |
| `levels/restaurant/stopwatch_level_data.gd` (`StopwatchLevelData`) | Herda `LevelData`: total de clientes, máximo ao mesmo tempo, cliente fica até ser atendido, regras das estrelas. |
| `levels/restaurant/componentes/customer_wave_director.gd` (`CustomerWaveDirector`) | Herda o `CustomerDirector`, com várias filas, número fixo de clientes e o "fica bravo e recomeça". |
| `levels/restaurant/componentes/customer_lane.gd` (`CustomerLane`) | Um lado de chegada: fila + entrada + para onde o cliente olha. |
| `levels/restaurant/componentes/fire_wall.gd` (`FireWall`) | Muro de fogo: colisão, chão queimado, chamas e luzes, montados pelo tamanho no Inspector. `ignite()` acende a partir da Brasa. |
| `levels/restaurant/ui/stopwatch_level_hud.gd` (`StopwatchLevelHUD`) | Mesmo `hud_fase.tscn` da fase 1, com outro script: cronômetro, clientes x/20, próxima estrela e tela de fim. |
| `entities/player/chef/habilidades/plant_ability.gd` (`PlantAbility`) | Habilidade de plantar (herda `AbilityComponent`): segura a tecla, conjura e a cena nasce à frente. Não sabe o que planta: Q e E são dois nós com cenas diferentes. |
| `entities/npcs/customers/pedido/pedido_so_cogumelo.tscn` | `pedido.tscn` com o cardápio só de cogumelo. |

Componentes reaproveitados sem mudar nada: chef, Brasa, `pe_cogumelo.tscn`, `raiz_espeto.tscn`, `tabua_corte.tscn`, `lixeira.tscn`, `QueueManager`, `CustomerDirector`, pedido, entrega, `PatienceAbilityTrigger`, magias dos 3 clientes, `ChargeRingComponent`, `SlowComponent`, `SpriteSheetEffect`, `FloatingText` e os bichos do mapa.

Mudança em arquivo que já existia:
- `level_select_map.gd`: guarda os resultados e libera a próxima bandeira.
- `project.godot`: ação nova `chef_desligado`, sem tecla, usada para desligar o dash nesta fase.

## Ajustes (Inspector / .tres)

- **Ritmo:** `spawn_interval_min/max` (9–14 s), `first_spawn_delay`, `patience_time` (60 s), `max_simultaneous` (12).
- **Magias:** `ability_thresholds` = [0.6, 0.25] → magia 1 e magia 2 (as ultimates ficam de fora na 1-1). Para ligar a 3ª, ponha um terceiro limite (ex.: 0.1).
- **Bravo:** `furious_patience_scale` (0.8) e `min_patience_time` (20 s). `customers_stay_until_served = false` volta ao comportamento antigo (vai embora bravo).
- **Muro:** `Mundo/MuroFogo` → `inner_size`, `thickness`, `flame_spacing`, `ignite_time`. Camada 6 (32): o chef usa máscara 37 nesta cena.
- **Plantar:** nós `PlantarCogumelo` / `PlantarGraveto` dentro do Chef → `conjure_time`, `max_alive`, `plant_distance`, `hold_to_conjure`, `allowed_area` (o lado de dentro do muro).
- **Filas:** `Filas/Cima|Baixo|Esquerda|Direita` → posição da `Fila`, `slot_spacing`, `Entrada`.

## Cuidados

- O fundo (`fundo_campo_1_1.png`) foi desenhado para o muro em (320,186) com 484x212 de dentro. Mudou o muro? Ajuste as faixas de terra do fundo também.
- A Sta.Toasty (placar e avisos) não tem acentos nem ★: os textos dela são escritos sem acento. O resumo do fim usa a Silver.
