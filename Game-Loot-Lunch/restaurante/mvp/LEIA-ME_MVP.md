# MVP — Loot & Lunch (restaurante)

Fluxo completo da demonstração:

```
Menu principal (UI/main_menu_rest.tscn)          <- cena principal do projeto (F5)
  ├─ Jogar     -> Fase 1 (leveis/lvl_1/lvl_1.tscn)
  ├─ Créditos  -> painel por cima do menu (mvp/ui/creditos_mvp.tscn)
  └─ Sair      -> fecha o jogo

Fase 1
  ├─ tempo acabou (bateu a meta OU NÃO) -> "Continuar" -> Boss VIP
  └─ chef caiu -> "Tentar de novo" (Fase 1 do zero) | "Sair para o menu"

Boss VIP (minigame/boss_fight_vip.tscn)
  ├─ perdeu em qualquer etapa -> "Tentar de novo" (repete a etapa) | "Sair para o menu"
  └─ venceu (Rainha morta, prato entregue, reação do VIP) -> Agradecimento

Agradecimento (mvp/agradecimento.tscn) -> "Voltar ao menu principal"
```

"Sair" sempre volta ao menu e "Jogar" sempre começa da Fase 1 (o MVP não tem save).

## Arquivos

| Arquivo | Papel |
|---|---|
| `mvp_flow.gd` (`MvpFlow`) | Único lugar que sabe a ORDEM das telas. `play_level_1`, `play_boss_fight`, `go_to_thanks`, `go_to_main_menu`. Troca de cena com a cortina do EasyTransition e despausa a árvore. |
| `fluxo_fase_1.tscn` (`MvpLevelFlow`) | Pendurado pelo MvpFlow na raiz da fase. Escuta `level_finished`, esconde a tela de fim do HUD da fase e mostra os botões do MVP. |
| `fluxo_boss_vip.tscn` (`MvpBossFlow`) | Pendurado pelo MvpFlow no BossFightVip. Liga `offer_quit_on_fail` e escuta `boss_fight_finished`. |
| `agradecimento.tscn` (`MvpThanks`) | Tela final: arte do menu, logo, agradecimento e botão para o menu. |
| `ui/creditos_mvp.tscn` (`MvpCredits`) | Créditos estáticos. A lista da equipe vem do `CredidsDB` (`menus/credits/credits_db.gd`) + `extra_members`. Textos editáveis no Inspector. |

As cenas do jogo **não sabem do MVP**: `lvl_1.tscn` e `boss_fight_vip.tscn` abertas
sozinhas (F6) funcionam como antes. O MVP só pendura o nó de fluxo nelas ao abrir.

## Mudanças fora desta pasta

- `UI/main_menu_rest.tscn` / `.gd`: agora usa o script `main_menu_rest.gd` (antes usava
  o `menus/main/main_menu.gd` do jogo principal). Só Jogar / Créditos / Sair; arte e
  animação iguais. A logo do GameLab só aparece na primeira vez que o menu abre.
  O botão está escrito "Creditos" sem acento porque a fonte dos botões (Sta.Toasty)
  não tem letras acentuadas.
- `minigame/comum/minigame_banner.gd`: novo `choose(título, texto, opções) -> índice`
  (painel com botões; setas/ESPAÇO/ENTER/clique; ESC = último botão) e `button_theme`.
- `minigame/boss_fight_vip.gd`: `offer_quit_on_fail` + sinal `quit_requested`
  (desligado por padrão: sem o MVP o comportamento é o mesmo de antes).
- `project.godot`: cena principal = `restaurante/UI/main_menu_rest.tscn`.

## Teste

Validado em Godot 4.7: menu → créditos → Jogar → chef caiu → tentar de novo → chef caiu
→ sair → Jogar → fim do turno → boss → etapa falhou → tentar de novo → falhou → sair →
boss vencido → agradecimento → menu.
