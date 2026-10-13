# Boss Fight — Cliente VIP

Cutscene de abertura + três minigames em sequência + cutscene final (a avaliação do VIP). Tudo fica em `restaurante/minigame/`.

| Cena | O que é |
|---|---|
| `boss_fight_vip.tscn` | **Gerenciador**: roda as etapas em ordem, repete a que falhar, mostra o prato e chama a avaliação do VIP. |
| `intro_vip/intro_vip.tscn` | Abertura — cutscene: o Coronel Ossvaldo chega e pede um prato com as tanajuras da fazenda dele |
| `carne_sol/carne_sol.tscn` | Fase 1 — Conjuração Solar (Carne de Sol) |
| `macaxeira_manteiga/macaxeira_manteiga.tscn` | Fase 2 — Alquimia de Cozimento (Macaxeira na Manteiga de Garrafa) |
| `farofa_tanajura/farofa_tanajura.tscn` | Fase 3 — Ritual Terrestre (chefe: Tanajura Rainha + 2 pequenas, depois a farofa) |
| `final_vip/avaliacao_vip.tscn` | Final — cutscene: o VIP prova o prato e reage (ruim / médio / bom / perfeito) |

**Testar:** abra qualquer uma dessas cenas e aperte **F6**. Cada etapa roda sozinha
(mostra as instruções, começa no ESPAÇO e `R` reinicia no fim).

## Controles

| Etapa | Controles |
|---|---|
| Fase 1 | **Segurar ESPAÇO** canaliza o Mini-Sol (barra verde sobe). **Soltar** tira a carne. **Clique** nas fagulhas antes que caiam na carne. |
| Fase 2 | A garrafa segue o **mouse**. **Segurar clique** despeja a manteiga (só conta em cima da macaxeira). **ESPAÇO** tira da chapa. |
| Fase 3 | Barrinha dourada do chef cheia: **1** Frigideirada, **2** Investida Sombria, **3** Besta, **4** Devorar (só com a formiga < 20%) — ou clique. **◀ ▶ / A D** (ou clique na formiga) trocam o alvo. Apertar antes da barra encher **agenda** o golpe. Formiga com **!** vai atacar: **ESPAÇO** no tempo do anel (investida, terremoto, pedras, cortes, formiga arremessada) e **clique** no buraco certo (cavar). Rainha voando: só a Besta. Bola de terra: 3 golpes na Rainha. |
| Cutscenes (abertura e avaliação) | **ESPAÇO**/clique avança a fala (1º toque completa o texto), **ESC** pula o diálogo. |

ESPAÇO = ação `chef_pick_drop`, clique = `left_click` (já existem no Input Map; nada novo foi adicionado ao `project.godot`).

## Arquitetura (componentes reaproveitáveis)

```
minigame/
├── boss_fight_vip.gd/.tscn        BossFightVip: sequência das etapas (não sabe o que cada uma faz)
├── comum/                         peças usadas por mais de uma etapa
│   ├── boss_minigame.gd           BossMinigame: base de etapa (begin/finish/teste com F6)
│   ├── minigame_banner.gd         MinigameBanner: painel de instruções/resultado + avisos
│   ├── target_meter_profile.gd    TargetMeterProfile (.tres): zonas e velocidades do "ponto"
│   ├── target_meter_component.gd  TargetMeterComponent: valor 0..1 que sobe/desce
│   ├── timing_gauge.gd            TimingGauge: barra com zona dourada (vertical/horizontal)
│   ├── qte_track.gd / qte_ring.gd QteTrack + QteRing: QTE de timing (1 ou N batidas)
│   ├── click_target_component.gd  ClickTargetComponent: alvo de clique (fagulha, buraco)
│   ├── battle_health_component.gd BattleHealthComponent: vida da batalha por turnos
│   ├── battle_wait_component.gd   BattleWaitComponent: TEMPO DE ESPERA (barra ATB) de quem luta
│   ├── boss_health_bar.gd         BossHealthBar: barra de vida gigante de chefe no topo da tela
│   ├── cutscene_stage.gd          CutsceneStage: base das cutscenes (andar, zoom, falas, pulinho, arco, efeito)
│   ├── dialogue_box.gd            DialogueBox: caixa de diálogo (retrato, nome, máquina de escrever, ESPAÇO/ESC)
│   ├── dialogo_vip.tscn           DialogueBox configurada: nome/cor/retrato do VIP e do Chef
│   ├── cinema_bars.gd             CinemaBars: faixas pretas de cinema + clarão
│   ├── salao_vip.tscn             salão do restaurante (porta, mesa, cadeira, luz) usado pelas 2 cutscenes
│   ├── sheet_sprite.gd            SheetSprite: AnimatedSprite2D montado de SheetAnimation (offset por animação, wait_frame)
│   └── anim/                      SheetAnimation do chef (idle/andar)
├── carne_sol/                     Fase 1: CarneSolMinigame, MiniSol, FagulhaSolar
├── macaxeira_manteiga/            Fase 2: MacaxeiraMinigame, GarrafaManteiga
├── intro_vip/                     ABERTURA: VipIntro (o Coronel chega e conversa com o chef)
├── final_vip/                     FINAL: VipTasting (cutscene da avaliação), GoldenRays
│   └── art/                       mesa, cadeira e garfada (provisórias)
└── farofa_tanajura/               Fase 3
    ├── batalha/                   TurnBattle (ATB), BattleMenu, Battler, ChefBattler, FormigaBattler, QueenAntBattler, TargetCursor
    │   ├── skills_rainha/         Arremesso, Voar, UltraArremesso, DevorarConjurar
    │   ├── skills/                BattleSkill + Frigideirada, InvestidaSombria, Besta, Devorar
    │   ├── skills_formiga/        FormigaSkill (+ contra-ataque) + Investida, Terremoto, LancarPedra, Cavar
    │   └── efeitos/               OndaTerremoto (reserva, se a arte da onda faltar)
    ├── cutscene/                  FarofaCutscene (cortar bundas, farinha, mexer)
    ├── entrega_vip/               EntregaVip, VipNpc (entrega antiga andando — não é mais usada)
    ├── dados/prato_vip.tres       ItemData do prato final
    └── art/                       arte (Entities/formiga, fx/formiga, fx/player) + art/anim/*.tres
```

Peças do restaurante que foram **reaproveitadas** (sem alterar nada nelas):
`FloatingText`, `SheetAnimation`, `ProgressBarComponent`, `ManaComponent`, `HudChef`/`ChefHUD`
(caveiras + mana na batalha), `ChefShadow`/`sombra.tscn` (Investida Sombria),
`DeliveryReceiverComponent` + `CarryableItem` + `ItemData` (entrega ao VIP), `chef.tscn`
(o chef jogável na entrega), arte da churrasqueira, da tábua, das tanajuras (`Ants.png`) e
os itens `farofa_de_tanajura_pronta.png` / `tanajura_limpa_preparada.png`.

### Regras que se repetem

- **A etapa é cena, a dificuldade é dado.** Ponto da carne, cozimento e dose de manteiga
  são `.tres` (`*/dados/*.tres`): mude velocidade/zonas no Inspector sem tocar no código.
- **Habilidade nova = nó filho.** Chef: script `extends BattleSkill` dentro do `chef_battler.tscn`
  (o menu lê nome/ícone/custo sozinho). Formiga: `extends FormigaSkill` dentro do `formiga.tscn`
  (sorteada por `weight`).
- **Etapa nova = cena que herda `BossMinigame`** + adicionar na lista `stages` do `BossFightVip`.

## Ligar no restaurante

```gdscript
var boss := preload("res://restaurante/minigame/boss_fight_vip.tscn").instantiate() as BossFightVip
add_child(boss)
var venceu: bool = await boss.boss_fight_finished  # (sucesso, resultados por etapa)
```

## Arte

- Gerada no padrão `arte_v2` (contorno `#2b1d0e`, 3–4 tons, luz de cima-esquerda, 32x32):
  estados da carne (derivados de `carne_bruta.png`), Mini-Sol, fagulha, macaxeira, chapa,
  garrafa, frigideira, bola de fogo, pedra, buraco, bunda de tanajura, farinha e o prato completo.
- **VIP:** `farofa_tanajura/art/Entities/NPC/vip-m/idle/jscoutinho_idle_VIP_34F.png` (4 quadros 32x32).

## Fase 3 — a TANAJURA RAINHA (update 03/10)

O **Cliente VIP** (no alto da arena) invoca as 2 tanajuras pequenas (saem do chão) e chama a
Rainha (desce do céu) — `FarofaTanajuraMinigame.summoner`. Luta em tempo ativo: **2 tanajuras pequenas + a Rainha** (chefe com asas, barra de vida
gigante no topo — `comum/boss_health_bar.gd`). A luta acaba quando a **Rainha** cai; as
pequenas fogem.

- **Tempo de espera** (`BattleWaitComponent`): chef 4 s, pequenas 4,5 s (±15%), Rainha 7 s.
  Enquanto alguém ataca/conjura, o relógio para e as outras esperam.
- **Pequenas** (`formiga.tscn`, 20 de vida): Investida, Terremoto, Lançar Pedra, Cavar — **meia
  caveira por acerto** (5 pedras = até 2,5 caveiras). Com a Rainha voando entram em **fúria**
  (`TurnBattle.rage_multiplier` = 2: 5 pedras = 5 caveiras).
- **Rainha** (`rainha.tscn`, `QueenAntBattler`, 110 de vida), habilidades em `batalha/skills_rainha/`:
  1. **Arremesso** — joga as pequenas no chef, uma de cada vez. ESPAÇO rebate (a formiga leva 8 e
     fica tonta); errou = 1 caveira por formiga. Sem pequenas no campo ela nem cogita.
  2. **Voar** — sobe por 12 s: só a **Besta** alcança (`BattleSkill.ranged`). Flechada derruba e
     **enche a mana** do chef. No céu ela não ataca e as pequenas entram em fúria.
  3. **Ultra Arremesso** — carrega a bola de terra por 13 s; **só o chef age** nesse tempo
     (`TurnBattle.channel`). 3 golpes nela = a bola cai em todas as formigas (12 de dano em cada);
     senão = 3 caveiras no chef, sem defesa.
  4. **Devorar e Conjurar** — PRIORIDADE MÁXIMA (`FormigaSkill.interrupts`): quando a vida dela
     chega em 60% e depois em 20% (só 2 vezes na partida, `devour_thresholds`) ela NÃO espera a
     barra dela — solta na hora (se estiver voando, desce antes) e as pequenas e o chef esperam.
     Devora as pequenas (+20% de vida por formiga, elas morrem sem drop), conjura 2 novas do chão
     e fica **20% mais rápida** a cada vez (`wait_multiplier` 0.8: espera 7 s → 5,6 s → 4,5 s).
     Nunca há mais de 2 pequenas (= vagas em `Formacao`).
  5. **Cortes de Vento** (básica) — o `lancar_pedra.gd` reaproveitado com `reflect = false`: até
     5 cortes, a frigideira só defende.
- **Chef**: Besta alcança voando; Frigideirada/Investida Sombria/Devorar não. Devorar só nas
  pequenas (`can_target_boss = false`), cura 2 caveiras.
- **Alvo bem visível**: a formiga na mira ganha a aura branca piscando (o mesmo `SpriteOutline`
  dos itens da cozinha) + a setinha. `TurnBattle.target_outline_color` / `target_outline_width`.
- **Mais tempo para defender**: `QteTrack.window_scale = 1.6` na fase 3 (todas as janelas de
  ESPAÇO 60% maiores), anel aparece 1 s antes (`ring_approach`), "!" fica 0,7 s em cima da formiga
  antes do ataque (`TurnBattle.alert_time`), Cavar: buraco treme 1,3 s + 1,2 s para clicar.
- Drops das pequenas vão para a pilha (`PilhaDrops`) e, no fim, até 5 viram farofa (a da Rainha
  vai junto).
- **Arte provisória** (feita no padrão da tanajura, troque quando a equipe mandar): asas
  `art/Entities/rainha/rainha_asas_4F.png` (4 quadros 56x48), bola `art/fx/rainha/bola_terra.png`
  (2 quadros 48x48), corte `art/fx/rainha/corte_vento.png` (3 quadros 32x16). O corpo da Rainha é
  a `tanajura_L_6F` em escala 3.
- Quadros 48x48 do chef: o chef fica em (4,16) → `offset (4,-8)` no `.tres` (o SheetSprite aplica
  sozinho e espelha com `flip_h`). Pulo 32x56 → `offset (0,-15)`.
- Arte velha que ficou sem uso (pode apagar): `skills/bolo_de_fogo.gd`, `art/bola_fogo.png`,
  `art/anim/bola_fogo_anim.tres`, `art/anim/formiga_morrer.tres`, `art/buraco_terra.png`,
  `art/pedra.png`, `art/bunda_tanajura.png`.

## Final — A AVALIAÇÃO DO VIP (update 03/10)

A entrega andando foi trocada por uma **cutscene** estilo Dave the Diver / o crítico do
Ratatouille (`final_vip/avaliacao_vip.tscn`, script `VipTasting`, herda `BossMinigame`):

1. Faixas pretas de cinema entram; o VIP espera sentado na mesa, sob a luz.
2. O chef entra com o prato na cabeça, serve ("Bon appétit!") e se afasta.
3. A câmera dá **zoom** no VIP, o fundo escurece, ele leva a garfada à boca, mastiga... "..."
4. **Reação** pelas estrelas das 3 etapas (`VipTasting.rate()`):

| Reação | Regra | O que acontece |
|---|---|---|
| **PERFEITO** | 3 estrelas em todas | raios dourados, flutua, clarão, brilhos, corações, confete |
| **BOM** | nenhuma abaixo de 2 e pelo menos uma com 3 | corações, pulinhos |
| **MÉDIO** | 2 estrelas em todas | aceno curto, "Aceitável..." |
| **RUIM** | alguma abaixo de 2 | fica verde, fumaça, treme e empurra o prato |

5. Câmera volta, o chef reage lá atrás, e o painel final mostra a reação com a cor dela.

- **Como as estrelas chegam:** o `BossFightVip` chama `set_results(resultados)` na etapa
  (se ela tiver esse método) antes do `begin()`. O resultado da cutscene traz `title`,
  `label`, `color` e `reaction`, que o painel final usa.
- **Testar cada reação (F6):** no Inspector da raiz troque `preview_stars`
  (ex.: `[3,3,3]` perfeito, `[3,2,2]` bom, `[2,2,2]` médio, `[1,3,3]` ruim).
- **Ajustes no Inspector:** falas de cada reação (`Falas`), `zoom_level`, `zoom_focus`,
  efeitos (`Efeitos`), `letterbox_height`.
- `GoldenRays` (`final_vip/golden_rays.gd`) é reaproveitável: raios girando atrás de
  qualquer coisa (`burst()` / `fade_out()`), desenhados por código.
- Arte da **mesa, cadeira e garfada** (`final_vip/art/`) é provisória: troque o PNG
  mantendo o nome. Os arquivos da entrega antiga (`farofa_tanajura/entrega_vip/`)
  continuam no projeto, mas não são mais usados.

## Abertura + diálogos (update 03/10)

- **`intro_vip/intro_vip.tscn` (`VipIntro`)** roda antes do painel de introdução
  (`BossFightVip.intro_stage`) e **não entra no placar**. Roteiro: salão vazio → porta abre
  ("tlim-tlim!") → o VIP entra → zoom nos dois → conversa → ele senta na mesa (o mesmo lugar
  onde prova o prato no final) → o chef vai para a cozinha → começam as etapas.
- O VIP agora tem nome: **Coronel Ossvaldo**, fazendeiro do Primeiro Andar da Masmorra que
  cria tanajuras gigantes (e elas comeram o chapéu dele). Na abertura ele avisa que trouxe
  "umas formigas de amostra" — é a deixa para a luta da Fase 3.
- **Final:** depois da reação, a câmera abre e os dois conversam (`outro_perfect`,
  `outro_good`, `outro_medium`, `outro_bad`). Em **BOM** e **PERFEITO** o Coronel convida o
  chef para fazer negócio na fazenda dele; o resultado traz `"farm_deal": true` e o placar
  final ganha a linha `deal_label` (para o jogo liberar a fazenda depois).
- **Falas:** ficam no Inspector (grupo "Falas") no formato `Quem: fala` (`VIP:` ou `Chef:`;
  sem "Quem:" ou começando com `*` = narração). Nome que aparece, cor e retrato ficam só em
  `comum/dialogo_vip.tscn` — trocar o nome do VIP é mudar `speaker_names` lá (as falas em
  que ele se apresenta pelo nome precisam ser trocadas à mão).
- **Reaproveitar em outra cena:** script `extends CutsceneStage`, adicione um nó
  `CinemaBars` e uma `DialogueBox` (ou instancie `dialogo_vip.tscn`), e escreva o roteiro no
  `_on_begin()` com `walk`, `zoom_to`, `talk`, `say`, `hop`, `squash`... Etapa com
  `show_intro_banner = false` entra direto, sem o painel de instruções.

## Ajustes (update 03/10, tarde)

- **Asas da Rainha:** quando ela é nocauteada, as asas param, caem e somem junto com o
  corpo (`QueenAntBattler.play_death`). A sombra também some.
- **Item "Asa de Formiga Rainha":** depois da vitória aparece o aviso
  "Você ganhou: Asa de Formiga Rainha!" e o ícone voa até o chef (`comum/loot_popup.gd`,
  `LootPopup.play(...)`, reaproveitável para baús/drops). **O item ainda não existe no
  jogo:** fica registrado em `"loot"` no resultado da Fase 3 (`[{id, name}]`) e aparece no
  painel "SUCESSO!" como "Item ganho: ...". Nome/id/ícone no Inspector da `rainha.tscn`
  (grupo "Recompensa"). Para entregar de verdade no futuro, procure o `TODO` em
  `BossFightVip._loot_text` e `FarofaTanajuraMinigame._award_boss_loot`.
- **Direção dos personagens nas cutscenes:** a arte do chef e do VIP (`jscoutinho_*`) olha
  para a **direita** (apesar do "_L" no nome; igual ao `sprite_faces_left = false` do
  chef.gd). O chef olha para a direita, e o VIP fica espelhado olhando para o chef
  (inclusive o retrato dele na caixa de diálogo: `speaker_portrait_flip`).

## Fase 3 — FASE FINAL da Rainha: as GUARDIÃS (update 04/10)

Quando a Rainha chega a **20%**, o Devorar e Conjurar dela vira a **fase final**:

1. Devora as formigas comuns (nesse limiar **não cura**: `final_heal_ratio = 0`, para a
   fase final ser de 20% para baixo; ponha 0.2 para voltar a curar).
2. Conjura **2 GUARDIÃS** (`batalha/formiga_guardia.tscn`): mesmas habilidades das comuns,
   **2x vida (40)**, armadura cinza-azulada com espinhos dourados
   (`art/Entities/guardia/guardia_L_6F.png`).
3. Levanta **voo na hora** (mais baixo: `final_flight_height`) e fica numa **bolha de
   proteção** (`comum/shield_bubble.gd`) com laços até as Guardiãs.

Regras da fase final:
- **Enquanto houver Guardiã viva, a Rainha não leva dano nenhum e não pode ser alvo**
  ("Protegida!"; ◀ ▶ pulam ela; a Besta não derruba). Matou as duas → a bolha estoura e
  ela fica vulnerável (o relógio do voo volta a contar; a Besta derruba, como antes).
- Com ela voando, as Guardiãs ficam em **FÚRIA** (dano dobrado), igual às comuns.
- Ela **ataca voando** (a espera dela continua enchendo no céu): **Cortes de Vento**
  (6 a 10 por vez em vez de até 5), **Raio Psíquico** e **Esferas Psíquicas**.
  **Ultra Arremesso (bola de terra) não sai mais** nesse estágio; Arremesso só no chão.
- **Raio Psíquico** (`skills_rainha/raio_psiquico.gd`): esfera na boca → feixe no chef →
  **martele o ESPAÇO** para encher a barra (`comum/mash_meter.gd`: 12 apertos em 3 s, a
  barra vaza sozinha). Encheu = segura o raio sem dano; senão dano proporcional ao que
  faltou (até 2 caveiras).
- **Esferas Psíquicas** (`skills_rainha/esferas_psiquicas.gd`): chuva de 12 esferas caindo
  em linha reta; um círculo no chão avisa onde cada uma cai. O chef anda **só para os
  lados (◀ ▶ / A D)** no espaço dele — da parede até um pouco antes das Guardiãs (faixa
  clara no chão; `comum/horizontal_dodge.gd`). Cada esfera = meia caveira.
- A Rainha **não morre antes da fase final**: um golpe que tiraria de 21% para 0 deixa ela
  com 1 de vida e a fase final começa em seguida ("Resiste!").

Peças novas reaproveitáveis: `ShieldBubble`, `MashMeter`, `HorizontalDodge`,
`PsychicBeam` (`batalha/efeitos/feixe_psiquico.gd`). Nas habilidades das formigas:
`FormigaSkill.phases` (em que fase pode sair: 0 normal, 1 final) e `usable_airborne`
(pode sair voando); `LancarPedra.stones_by_phase` (quantidade por fase).

**Balanceamento (bot):** com 85% de acerto nos QTEs vence ~2 em 3 lutas; com 80%, ~metade.
Bem mais difícil que antes, como pedido.

## Fase 3 — mana do DESCANSO (update 04/10)

Se a barra de espera do chef está **cheia** (ele pode atacar) e o jogador **não escolhe
nenhum ataque**, o chef descansa e ganha **2 de mana por minuto** (+1 a cada 30 s, com o
aviso "+1 mana (descanso)"). Conta o tempo de verdade, inclusive enquanto as formigas
atacam. Atacou = o descanso recomeça do zero. Mana cheia = não junta.
Ajuste em `chef_battler.tscn` → `rest_mana_per_minute` (0 desliga).
Código: `ChefBattler.tick_rest()` / `reset_rest()`, chamados pelo `TurnBattle._process()`.

