# Boss Fight — Cliente VIP

Três minigames em sequência + entrega final. Tudo fica em `restaurante/minigame/`.

| Cena | O que é |
|---|---|
| `boss_fight_vip.tscn` | **Gerenciador**: roda as etapas em ordem, repete a que falhar, mostra o prato e chama a entrega. |
| `carne_sol/carne_sol.tscn` | Fase 1 — Conjuração Solar (Carne de Sol) |
| `macaxeira_manteiga/macaxeira_manteiga.tscn` | Fase 2 — Alquimia de Cozimento (Macaxeira na Manteiga de Garrafa) |
| `farofa_tanajura/farofa_tanajura.tscn` | Fase 3 — Ritual Terrestre (batalha por turnos + farofa) |
| `farofa_tanajura/entrega_vip/entrega_vip.tscn` | Final — andar até o VIP com o prato |

**Testar:** abra qualquer uma dessas cenas e aperte **F6**. Cada etapa roda sozinha
(mostra as instruções, começa no ESPAÇO e `R` reinicia no fim).

## Controles

| Etapa | Controles |
|---|---|
| Fase 1 | **Segurar ESPAÇO** canaliza o Mini-Sol (barra verde sobe). **Soltar** tira a carne. **Clique** nas fagulhas antes que caiam na carne. |
| Fase 2 | A garrafa segue o **mouse**. **Segurar clique** despeja a manteiga (só conta em cima da macaxeira). **ESPAÇO** tira da chapa. |
| Fase 3 | Seu turno: **1** Frigideirada, **2** Investida Sombria, **3** Bolo de Fogo, **4** Devorar (só com a formiga < 20%) — ou clique. Turno da formiga: **ESPAÇO** no tempo do anel (investida, terremoto, cada pedra) e **clique** no buraco certo (cavar). |
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
│   ├── sheet_sprite.gd            SheetSprite: AnimatedSprite2D montado de SheetAnimation
│   └── anim/                      SheetAnimation do chef (idle/andar)
├── carne_sol/                     Fase 1: CarneSolMinigame, MiniSol, FagulhaSolar
├── macaxeira_manteiga/            Fase 2: MacaxeiraMinigame, GarrafaManteiga
└── farofa_tanajura/               Fase 3 + final
    ├── batalha/                   TurnBattle, BattleMenu, Battler, ChefBattler, FormigaBattler
    │   ├── skills/                BattleSkill + Frigideirada, InvestidaSombria, BoloDeFogo, Devorar
    │   ├── skills_formiga/        FormigaSkill + Investida, Terremoto, LancarPedra, Cavar
    │   └── efeitos/               OndaTerremoto
    ├── cutscene/                  FarofaCutscene (cortar bundas, farinha, mexer)
    ├── entrega_vip/               EntregaVip, VipNpc
    ├── dados/prato_vip.tres       ItemData do prato final
    └── art/                       arte nova (pixel art no padrão arte_v2) + art/anim/*.tres
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
- **VIP:** coloque `jscoutinho_idle_VIP_34F.png` em
  `farofa_tanajura/art/Entities/NPC/vip-m/idle/`. Até lá a entrega usa uma arte provisória
  (esqueleto dourado) e avisa no Output.
