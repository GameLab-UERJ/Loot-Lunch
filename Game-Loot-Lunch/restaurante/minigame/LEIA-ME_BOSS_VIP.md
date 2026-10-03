# Boss Fight — Cliente VIP

Três minigames em sequência + entrega final. Tudo fica em `restaurante/minigame/`.

| Cena | O que é |
|---|---|
| `boss_fight_vip.tscn` | **Gerenciador**: roda as etapas em ordem, repete a que falhar, mostra o prato e chama a entrega. |
| `carne_sol/carne_sol.tscn` | Fase 1 — Conjuração Solar (Carne de Sol) |
| `macaxeira_manteiga/macaxeira_manteiga.tscn` | Fase 2 — Alquimia de Cozimento (Macaxeira na Manteiga de Garrafa) |
| `farofa_tanajura/farofa_tanajura.tscn` | Fase 3 — Ritual Terrestre (batalha em tempo ativo contra 5 formigas + farofa) |
| `farofa_tanajura/entrega_vip/entrega_vip.tscn` | Final — andar até o VIP com o prato |

**Testar:** abra qualquer uma dessas cenas e aperte **F6**. Cada etapa roda sozinha
(mostra as instruções, começa no ESPAÇO e `R` reinicia no fim).

## Controles

| Etapa | Controles |
|---|---|
| Fase 1 | **Segurar ESPAÇO** canaliza o Mini-Sol (barra verde sobe). **Soltar** tira a carne. **Clique** nas fagulhas antes que caiam na carne. |
| Fase 2 | A garrafa segue o **mouse**. **Segurar clique** despeja a manteiga (só conta em cima da macaxeira). **ESPAÇO** tira da chapa. |
| Fase 3 | Barrinha dourada do chef cheia: **1** Frigideirada, **2** Investida Sombria, **3** Besta, **4** Devorar (só com a formiga < 20%) — ou clique. **◀ ▶ / A D** (ou clique na formiga) trocam o alvo. Apertar antes da barra encher **agenda** o golpe. Formiga com **!** vai atacar: **ESPAÇO** no tempo do anel (investida, terremoto, cada pedra) e **clique** no buraco certo (cavar). |
| Entrega | **WASD** anda, **ESPAÇO** de frente para o VIP entrega. |

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
│   ├── sheet_sprite.gd            SheetSprite: AnimatedSprite2D montado de SheetAnimation (offset por animação, wait_frame)
│   └── anim/                      SheetAnimation do chef (idle/andar)
├── carne_sol/                     Fase 1: CarneSolMinigame, MiniSol, FagulhaSolar
├── macaxeira_manteiga/            Fase 2: MacaxeiraMinigame, GarrafaManteiga
└── farofa_tanajura/               Fase 3 + final
    ├── batalha/                   TurnBattle (ATB), BattleMenu, Battler, ChefBattler, FormigaBattler, TargetCursor
    │   ├── skills/                BattleSkill + Frigideirada, InvestidaSombria, Besta, Devorar
    │   ├── skills_formiga/        FormigaSkill (+ contra-ataque) + Investida, Terremoto, LancarPedra, Cavar
    │   └── efeitos/               OndaTerremoto (reserva, se a arte da onda faltar)
    ├── cutscene/                  FarofaCutscene (cortar bundas, farinha, mexer)
    ├── entrega_vip/               EntregaVip, VipNpc
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

## Fase 3 — batalha em tempo ativo (update 02/10)

- **As 5 formigas lutam juntas**, em formação (nó `Formacao`, 5 `Marker2D`). Cada lutador tem um
  `BattleWaitComponent`: o relógio corre, a barra enche e quem encher age. Enquanto alguém ataca o
  relógio para (um QTE por vez). `TurnBattle.active_time` ligado = o relógio NÃO para com o menu
  aberto (pensou demais, apanha). Desligue para o modo "espera".
- **2 formigas rápidas** (`FarofaTanajuraMinigame.fast_ant_count` / `fast_wait_time` = 4 s contra
  7 s das normais, ±20%). São sorteadas e **não aparecem na tela**.
- **Contra-ataques** (arte `fx/player/contra`): investida → `contra_frigideirada`, pedra →
  `contra_rebater`, cavar → `contra_martelada`, terremoto → `pulo` + `poeira_pouso`. Contra
  certeiro deixa a formiga **tonta** (`counter_daze`, estrelinhas): a espera dela para.
- **Frigideirada e Besta atrasam** a espera do alvo (`wait_knock_back`).
- **Besta** substituiu o Bolo de Fogo (mesmo custo: 2 de mana, 13 de dano). Mana igual: 5 barras,
  Frigideirada e Devorar dão +1, Investida Sombria custa 1.
- Números de dificuldade (tudo no Inspector): formiga 30 HP; investida 3, terremoto 3, cavar 3,
  pedra 1 cada; chef 10 (5 caveiras), espera do chef 1,5 s; Devorar cura 2.
- Quadros 48x48 do chef: o chef fica em (4,16) → `offset (4,-8)` no `.tres` (o SheetSprite aplica
  sozinho e espelha com `flip_h`). Pulo 32x56 → `offset (0,-15)`.
- Arte velha que ficou sem uso (pode apagar): `skills/bolo_de_fogo.gd`, `art/bola_fogo.png`,
  `art/anim/bola_fogo_anim.tres`, `art/anim/formiga_morrer.tres`, `art/buraco_terra.png`,
  `art/pedra.png`, `art/bunda_tanajura.png`.
