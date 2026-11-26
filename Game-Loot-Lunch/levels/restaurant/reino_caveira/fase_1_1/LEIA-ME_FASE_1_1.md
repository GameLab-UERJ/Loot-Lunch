# Fase 1-1 — Portão de Ossos (campo aberto + muro de fogo)

Cena: `levels/restaurant/reino_caveira/fase_1_1/fase_1_1.tscn` (F6 testa sozinha). No mapa Reino Caveira, a bandeira 1-1 abre esta fase.

## Como é

- Mesmas dimensões da primeira cozinha (640x360), mas é um **campo aberto** do Reino Caveira.
- A **Brasa acende um muro de fogo** em volta do campo no começo da fase. O chef e a Brasa ficam dentro; os clientes não entram.
- **10 clientes** (Johnny, Mandy e Patolino) chegam pelos **4 lados**, até 3 por lado: em cima, embaixo, à esquerda e à direita.
- Cada cliente fica **travado no fogo** e lança a magia 1 e a magia 2 quando a barra de paciência cai (60% e 25%).
- **Paciência em 0 = RAIVA PURA.** Ele não vai embora e a barra não recomeça: fica vazia, o cliente pisca vermelho ("RAIVA PURA!") e passa a lançar a magia 1 e a magia 2 **sem parar** (sorteando entre as duas, mais ou menos 1 por segundo) até ser atendido.
- A entrega é por cima do muro: chegue na beirada do fogo de frente para o cliente e aperte ESPAÇO.
- **Só cogumelo** nesta fase: os pedidos são espetinho de cogumelo, no ponto ou torrado.
- O **relógio anda para frente** e cronometra quanto tempo vocês levam para atender os 10.

## Cenário (estações fixas)

Tudo já vem no mapa, dentro de `Mundo/Estacoes`. O chef **não planta nada**.

| Nó | Posição | O que é |
|---|---|---|
| `PeCogumeloEsquerda` / `PeCogumeloMeio` / `PeCogumeloDireita` | (140,130) / (320,108) / (500,130) | `pe_cogumelo.tscn`: colhe com ESPAÇO, volta a crescer em 5 s |
| `TabuaCorteEsquerda` / `TabuaCorteDireita` | (226,190) / (414,190) | `tabua_corte.tscn` |
| `RaizEspetoEsquerda` / `RaizEspetoDireita` | (226,240) / (414,240) | `raiz_espeto.tscn`: monta o espetinho |
| `Lixeira` | (320,270) | `lixeira.tscn` |

Cada lado tem o caminho completo: pé de cogumelo → tábua logo abaixo → raiz de espeto logo abaixo. O pé do meio serve aos dois lados.

## Estrelas (no `fase_1_1.tres`)

| Estrelas | Pedidos certos | Tempo |
|---|---|---|
| ★ | 5 ou mais | qualquer (é o mínimo para passar) |
| ★★ | 7 ou mais | até 5:00 |
| ★★★ | 9 ou mais | até 3:45 |

Os números ficam em `star_min_correct` e `star_max_time` (0 = sem limite). O placar mostra a melhor estrela que ainda dá para pegar, e muda quando o tempo passa do limite ou faltam clientes para chegar nos certos.

O resultado fica guardado durante a sessão: a bandeira 1-1 do mapa mostra as estrelas e a 1-2 é liberada quando a 1-1 tem pelo menos 1 estrela.

## Controles

| Quem | Tecla | O que faz |
|---|---|---|
| Chef | WASD | anda |
| Chef | ESPAÇO | pega / colhe / corta / usa / entrega |
| Chef | R | joga fora |
| Brasa | setas | anda (é a churrasqueira) |

O Shift (dash) e as habilidades do chef (arremesso e sombra) estão **desligados nesta fase**. A ideia é o jogador ganhar essas habilidades com o tempo.

**Fluxo:** ESPAÇO colhe o cogumelo no pé → tábua (ESPAÇO x5) → raiz de espeto (2 cogumelos cortados) → espetinho cru → Brasa (assa) → cliente.

Se o chef cair, ele volta depois de 3 s com a vida cheia (`revive_delay`). Só perde tempo, porque `fail_on_chef_death` está desligado no `.tres`.

## Scripts

| Arquivo | O que é |
|---|---|
| `levels/restaurant/stopwatch_level.gd` (`StopwatchLevel`) | Fase com cronômetro: acende o muro, liga o diretor, conta o tempo, decide as estrelas, guarda o resultado no mapa, "Jogar de novo" / "Voltar ao mapa". |
| `levels/restaurant/stopwatch_level_data.gd` (`StopwatchLevelData`) | Herda `LevelData`: total de clientes, máximo ao mesmo tempo, cliente fica até ser atendido, raiva pura, regras das estrelas. |
| `levels/restaurant/componentes/customer_wave_director.gd` (`CustomerWaveDirector`) | Herda o `CustomerDirector`, com várias filas, número fixo de clientes e o que acontece quando a paciência zera (raiva pura ou recomeçar a barra). |
| `entities/npcs/customers/componentes/customer_rage_component.gd` (`CustomerRageComponent`) | **Raiva pura**, reutilizável em qualquer cliente: `start()` faz ele pulsar vermelho e lançar as magias de `levels` a cada `cast_interval`; `stop()` encerra. Não sabe o que cada magia faz: usa `cast_for_patience_level`. O diretor cria o nó "Raiva" sozinho quando a paciência zera. |
| `levels/restaurant/componentes/customer_lane.gd` (`CustomerLane`) | Um lado de chegada: fila + entrada + para onde o cliente olha. |
| `levels/restaurant/componentes/fire_wall.gd` (`FireWall`) | Muro de fogo: colisão, chão queimado, chamas e luzes, montados pelo tamanho no Inspector. `ignite()` acende a partir da Brasa. |
| `levels/restaurant/ui/stopwatch_level_hud.gd` (`StopwatchLevelHUD`) | Mesmo `hud_fase.tscn` da fase 1, com outro script: cronômetro, clientes x/total, próxima estrela e tela de fim. |
| `entities/npcs/customers/pedido/pedido_so_cogumelo.tscn` | `pedido.tscn` com o cardápio só de cogumelo. |

`entities/player/chef/habilidades/plant_ability.gd` (`PlantAbility`) **não é mais usado** em nenhuma cena: o plantar saiu do jogo. Pode apagar o arquivo (e o `.uid` dele) se não for reaproveitar.

Componentes reaproveitados: chef, Brasa, `pe_cogumelo.tscn`, `raiz_espeto.tscn`, `tabua_corte.tscn`, `lixeira.tscn`, `QueueManager`, `CustomerDirector`, pedido, entrega, `PatienceAbilityTrigger`, magias dos 3 clientes, `ChargeRingComponent`, `SlowComponent`, `SpriteSheetEffect`, `FloatingText` e os bichos do mapa.

Mudança em arquivo que já existia:
- `level_select_map.gd`: guarda os resultados e libera a próxima bandeira.
- `project.godot`: ação nova `chef_desligado`, sem tecla, usada para desligar o dash nesta fase.
- `customer.gd`: a paciência só começa na **primeira** chegada à fila. Antes, quando a fila andava, a barra de quem já tinha zerado enchia de novo.

## Ajustes (Inspector / .tres)

- **Clientes:** `total_customers` (10), `max_simultaneous` (12).
- **Ritmo:** `spawn_interval_min/max` (9–14 s), `first_spawn_delay`, `patience_time` (60 s).
- **Magias (antes de zerar):** `ability_thresholds` = [0.6, 0.25] → magia 1 e magia 2 (as ultimates ficam de fora na 1-1). Para ligar a 3ª, ponha um terceiro limite (ex.: 0.1).
- **Raiva pura:** `rage_when_patience_ends` (true), `rage_ability_levels` ([1, 2] — ponha 3 para a ultimate entrar também), `rage_cast_interval` (1.0 s — menor = mais desenfreado). No `CustomerRageComponent` ainda dá para mexer em `interval_jitter`, `wait_for_previous`, `rage_color` e `pulse_time`.
- **Sem raiva:** `rage_when_patience_ends = false` volta ao "fica bravo e a barra recomeça" (`furious_patience_scale` 0.8, `min_patience_time` 20 s). `customers_stay_until_served = false` volta ao mais antigo (vai embora bravo).
- **Estações:** mova os nós dentro de `Mundo/Estacoes` (fique dentro do muro: x 78–562, y 80–292).
- **Muro:** `Mundo/MuroFogo` → `inner_size`, `thickness`, `flame_spacing`, `ignite_time`. Camada 6 (32): o chef usa máscara 37 nesta cena.
- **Filas:** `Filas/Cima|Baixo|Esquerda|Direita` → posição da `Fila`, `slot_spacing`, `Entrada`.

## Cuidados

- O fundo (`fundo_campo_1_1.png`) foi desenhado para o muro em (320,186) com 484x212 de dentro. Mudou o muro? Ajuste as faixas de terra do fundo também.
- A Sta.Toasty (placar e avisos) não tem acentos nem ★: os textos dela são escritos sem acento. O resumo do fim usa a Silver.
