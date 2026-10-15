# Tutoriais em quadro-negro + teclas na tela

Telas de tutorial desenhadas (no estilo das receitas do Overcooked) para cada cenário do MVP,
e o aviso de TECLA em cima do chef nos ataques da batalha.

## Onde estão

| Cenário | Tutorial | Páginas |
|---|---|---|
| Fase 1 (`leveis/lvl_1/lvl_1.tscn`) | `leveis/lvl_1/tutorial_lvl_1.tscn` | Espetinho na brasa · O ponto certo · Controles |
| Carne de Sol (`minigame/carne_sol/carne_sol.tscn`) | `minigame/carne_sol/tutorial_carne_sol.tscn` | 1 página |
| Macaxeira (`minigame/macaxeira_manteiga/macaxeira_manteiga.tscn`) | `minigame/macaxeira_manteiga/tutorial_macaxeira.tscn` | 1 página |
| Farofa / batalha (`minigame/farofa_tanajura/farofa_tanajura.tscn`) | `minigame/farofa_tanajura/tutorial_farofa.tscn` | Sua vez de atacar · Barra de turnos · Defenda-se · A Rainha |

**Testar:** abra a cena do tutorial e aperte **F6** (o quadro abre sozinho; fechou = sai).

## Como aparece no jogo

- **Fase 1:** o quadro abre antes de o relógio começar (o jogo fica pausado). Só na primeira vez
  da sessão (`RestaurantLevel.tutorial_once`): "Tentar de novo" não mostra de novo.
  **F1** reabre o tutorial no meio da fase (`tutorial_key`).
- **Boss do VIP:** na PRIMEIRA vez de cada etapa o quadro aparece no lugar do painel de
  instruções. Se o jogador falhar e tentar de novo, volta o painel de texto de antes.
- **F6 numa etapa:** sempre mostra o quadro antes de começar.
- No quadro: **ESPAÇO / ENTER / clique / ▶** = próxima página (na última, começa) ·
  **◀** = volta · **ESC** = pula.

Ligado pelo Inspector: `tutorial` (PackedScene) na raiz da fase (`RestaurantLevel`) e na raiz
de cada etapa (`BossMinigame`). Vazio = sem tutorial.

## Peças (reaproveitáveis)

```
UI/tutorial/
├── tutorial_board.gd      TutorialBoard: o quadro (moldura, título, etiqueta, legenda, rodapé,
│                          páginas, pausa). `await TutorialBoard.play(self, cena, so_uma_vez)`
├── tutorial_page.gd       TutorialPage: uma página (título, legenda com BBCode, etiqueta)
├── chalk_doodle.gd        ChalkDoodle: rabiscos de giz por código (seta, círculo, barrinha com
│                          faixa dourada, número, X, ✓, brilho, "!", anel de QTE, arco pontilhado)
├── chalk_sprite.gdshader  giz na arte do jogo (contorno claro + granulado)
└── chalk_material.tres    material pronto com o shader de giz
componentes/
├── key_cap.gd             KeyCap: tecla desenhada (ESPAÇO, setas, mouse com botão aceso, letras)
└── key_prompt.gd          KeyPrompt: tecla(s) + texto em cima de alguém ("ESPAÇO / REBATA!")
```

Tudo com `@tool`: abrindo a cena do tutorial no editor, o quadro aparece montado.
`editor_page` (na raiz do quadro) troca a página mostrada no editor.

### Editar um desenho

Cada página é um `Node2D` (TutorialPage) com os desenhos dentro, em coordenadas da tela
(640x360). Área livre: de y ≈ 56 até y ≈ 290.

- **Arte do jogo:** `Sprite2D` / `AnimatedSprite2D` (SheetSprite) com `material = chalk_material.tres`.
- **Setas e rabiscos:** nó com `chalk_doodle.gd` — mude `shape`, `points`, `bend`, `color`, `animate`.
- **Teclas:** nó com `key_cap.gd` — `key` = `SPACE`, `LEFT`, `RIGHT`, `MOUSE_LEFT`, `Q`, `1`...;
  `pressing` (afunda sozinha) ou `held` (afundada = "segure").
- **Textos:** `Label` com a fonte Silver (tem acento). O título usa a fonte do menu, que NÃO tem
  acento: o que faltar sai na Silver.
- **Aura verde/vermelha:** `Sprite2D` com o `aura_outline.gdshader` atrás do balão (a cor vem do
  `modulate`), igual ao `pedido.tscn`.

Página nova = duplique uma página (Ctrl+D) e troque o desenho. Tutorial novo = duplique uma das
cenas e ligue no `tutorial` da fase/etapa.

## Teclas na batalha (Fase 3)

Quando um ataque inimigo começa, a tecla aparece GRANDE em cima do chef e acende quando é a hora:

| Ataque | Aviso |
|---|---|
| Investida | ESPAÇO + "DEFENDA!" |
| Terremoto | ESPAÇO + "PULE!" |
| Lançar Pedra / Arremesso | ESPAÇO + "REBATA!" |
| Cortes de Vento | ESPAÇO + "DEFENDA!" |
| Cavar | botão ESQUERDO do mouse + "CLIQUE NO BURACO QUE TREME!" |
| Raio Psíquico | ESPAÇO afundando rápido + "MARTELE!" |
| Esferas Psíquicas | ◀ ▶ + "DESVIE!" (acompanha o chef) |
| Bola de Terra (Ultra Arremesso) | 1 2 3 4 + "GOLPEIE A RAINHA x/3!" |

- Os ataques com anel usam o `QteTrack`: a tecla sai sozinha da ação (`chef_pick_drop` → ESPAÇO),
  aparece junto com o primeiro anel e acende (amarela) quando a janela abre.
  Texto: `battle.qte.prompt_caption = "..."` antes do `run`. Desligar: `QteTrack.show_key_prompt`.
- Cavar: `prompt_caption` / `prompt_offset` no nó `Cavar` da `formiga.tscn`.
- Nada mudou no `project.godot` (F1 é lido direto pela fase).
