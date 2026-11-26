# Seleção de fase — mapa "Reino Caveira"

Mapa estilo Overcooked, todo em pixel art e sem partes escondidas: floresta macabra com árvores-cogumelo, caveiras, brejo, ponte, cemitério, ossada gigante e o Castelo Caveira. O chef e a Brasa andam juntos pelo mapa e escolhem a fase parando numa bandeira.

Cena: `levels/restaurant/selecao_fase/reino_caveira/reino_caveira.tscn` (F6 testa sozinha).

## Controles

| Quem | Anda | Jogar a fase |
|---|---|---|
| Chef | WASD | ESPAÇO (`chef_pick_drop`) |
| Brasa | setas | ENTER (`brasa_interact`, ação nova) |

Ficar em cima de uma bandeira mostra embaixo: número, nome, estrelas e a dica de tecla.
- Fase trancada → a bandeira treme e aparece "Trancada!".
- Fase sem cena → "Em breve!".
- Fase liberada com cena → cortina do EasyTransition e troca de cena.

## Os 7 pontos de fase

| Ponto | Nome | Estado inicial |
|---|---|---|
| 1-1 | Portão de Ossos | liberada → abre `fase_1_1.tscn` |
| 1-2 | Clareira das Teias | trancada |
| 1-3 | Cemitério Cogumelo | trancada |
| 1-4 | Bosque dos Morcegos | trancada |
| 1-5 | Brejo do Olho | trancada (do outro lado da ponte) |
| 1-6 | Ossada do Gigante | trancada |
| 1-7 | Castelo Caveira | trancada (na frente do castelo) |

**Progresso:** a fase guarda o resultado (`LevelSelectMap.record_result`). Ao voltar ao mapa, a bandeira mostra as estrelas, a próxima é liberada (se a anterior tem 1 estrela ou mais) e os jogadores aparecem na bandeira jogada. Vale durante a sessão: o jogo ainda não tem save.

**Ligar uma fase:** selecione `Mundo/Fase1` e preencha `level_scene` no Inspector (ex.: `lvl_1.tscn`). `locked`, `stars`, `level_name` e `level_id` ficam no mesmo lugar e aparecem no editor na hora.

## Estrutura

```
ReinoCaveira (Node2D, LevelSelectMap)
├── Noite            CanvasModulate (deixa o mapa noturno; as luzes dão o brilho)
├── Fundo            Sprite2D fundo_reino_caveira.png (640x360, z -10): chão, trilha, brejo, ponte, caveiras
├── Bordas / Brejo / Ossada   StaticBody2D (camada 1): bordas, água (só a ponte passa) e a ossada
├── Mundo            Node2D com y_sort (o chef passa por trás dos chapéus)
│   ├── Fase1..Fase7     ponto_fase.tscn (LevelSelectNode)
│   ├── Castelo          StaticBody2D + sprite + luzes dos olhos
│   ├── Arvore1..N       arvore_cogumelo.tscn (MushroomTree), algumas com Aranha pendurada
│   ├── OlhoBrejo, Cogumelinho, Corvo, Vela   bichos de chão
│   ├── Chef             chef.tscn (InputComponent -> ActionInputComponent WASD, HUD escondido)
│   └── Brasa            brasa.tscn (labareda aleatória desligada aqui, com luz)
├── Ceu (z 5)        morcegos, alminhas e vagalumes (CPUParticles2D)
├── Teias (z 6)      teias de canto e teias pequenas
└── Interface        hud_selecao_fase.tscn (LevelSelectHUD)
```

## Scripts novos (reutilizáveis para outros mapas)

| Arquivo | O que é |
|---|---|
| `level_select_map.gd` (`LevelSelectMap`) | Raiz de qualquer mapa de seleção: acha os pontos, posiciona os jogadores, lê a tecla de cada um, mostra o HUD e troca de cena. Sinais `level_selected` / `level_refused`. Exports: `players`, `confirm_actions`, `confirm_key_names`, `require_all_players` (os dois na bandeira), `spawn_node_index`. |
| `level_select_node.gd` (`LevelSelectNode`) + `ponto_fase.tscn` | A bandeira de uma fase: dados da fase + visual (bandeira, cadeado, estrelas, anel que pulsa). Usa o `ProximityComponent` que já existia para saber quem está em cima. |
| `level_select_hud.gd` + `hud_selecao_fase.tscn` | Placa do mapa com o total de estrelas, painel da fase e aviso. |
| `ambient_creature.gd` (`AmbientCreature`) | Bicho de cenário sem colisão: PARADO, VOO, PENDURADO (com fio), FLUTUAR, PASSEAR. Usa o `SheetRowSprite` que já existia. |
| `reino_caveira/mushroom_tree.gd` (`MushroomTree`) + `arvore_cogumelo.tscn` | Árvore-cogumelo: `variant` (0–9) troca o desenho no editor, `flip` espelha. Colisão só no talo. |

Componentes que já existiam e foram reaproveitados: `ProximityComponent`, `SheetRowSprite`, `FloatingText`, `ActionInputComponent` (da Brasa), `DayNightSwitch`, chef e Brasa inteiros.

## Bichos de cenário (`reino_caveira/bichos/`)

Morcego (voa em 8), aranha (desce e sobe no fio), alminha (fogo-fátuo com carinha de caveira, com luz), cogumelinho andante, corvo-caveira, olho do brejo (sobe do brejo, olha para os lados, pisca e afunda) e vela de caveira (com luz). Nenhum interage com os jogadores. Para pôr mais, arraste a cena do bicho para `Mundo` (no chão) ou `Ceu` (voando) e ajuste `area` / `speed`.

## Arte (`assets/art/restaurant/mapa/reino_caveira/`)

`fundo_reino_caveira.png`, `arvores_cogumelo.png` (10 variantes 56x64), `castelo_caveira.png`, `ponto_base.png`, `ponto_bandeira.png` (linha 1 = liberada, linha 2 = trancada), `cadeado.png`, `estrela.png` (cheia/vazia), `teia_canto.png`, `teia_pequena.png` e as tiras dos bichos.

## Colisões

Tudo na camada 1 (a mesma das paredes da cozinha): bordas, água do brejo (a ponte tem 24 px livres), talos das árvores, castelo e a ossada. Bichos, teias e decoração do chão não têm colisão.
