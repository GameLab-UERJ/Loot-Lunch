# Cenário do restaurante (tiles 16x16) e fundos dos mini games

## Fase 1 — tiles

| Arquivo | O que é |
|---|---|
| `cenario/restaurante_tileset_16x16.png` | Folha de tiles (8 colunas, 16x16, sem espaçamento). |
| `cenario/restaurante_tileset.tres` | TileSet (fonte 0 = a folha). Já tem colisão nos tiles certos. |
| `leveis/lvl_1/cenario_lvl_1.tscn` | Cenário da fase 1 pintado em 5 TileMapLayers. Instanciado em `lvl_1.tscn` → `Cenario/CenarioTiles`. |

Camadas (de baixo para cima): **Chao** (grama, piso, calçada, meio-fio) → **Sombras** → **Paredes** → **Balcao** → **Decoracao**.
Para mexer: abra `cenario_lvl_1.tscn`, escolha a camada e pinte com o TileSet.
Fase nova: duplique `cenario_lvl_1.tscn` e repinte.

### Colisão (está no TileSet, não precisa de StaticBody2D)
- Camada de física 0 → **camada 1** (paredes): `topo_*`, `parede_alta_*`, `meio_fio` (quadrado inteiro) e `parede_baixa_*` (12 px de cima).
- Camada de física 1 → **camada 6 = valor 32** (balcão, só o chef colide; magias e arremessos passam): `balcao_*` e `guia_portao_*`.
- Os tiles de sombra e de decoração não têm colisão.

### Medidas da fase 1 (640x360)
Parede de cima até y 44 · cozinha x 32–608, y 44–256 · balcão y 257–271 · calçada (clientes) y 272–320 · meio-fio y 320–336.

### Tiles (coluna, linha na folha)
| Grupo | Tiles |
|---|---|
| Piso | `piso_a` (0,0), `piso_b` (1,0), `piso_c` (2,0), `piso_rachado` (3,0), `piso_gasto` (4,0), `piso_tabua_solta` (5,0) |
| Parede | `parede_alta_a` (6,0), `parede_alta_b` (7,0), `parede_baixa_a` (0,1), `parede_baixa_b` (1,1) |
| Topo da parede | `topo_h` (2,1), `topo_v` (3,1), `topo_canto_se` (4,1), `topo_canto_sd` (5,1), `topo_ponta_baixo` (6,1), `topo_ponta_esq` (7,1), `topo_ponta_dir` (0,2), `topo_cheio` (1,2) |
| Balcão | `balcao_esq` (2,2), `balcao_meio_a` (3,2), `balcao_meio_b` (4,2), `balcao_boteco` (5,2), `balcao_dir` (6,2), `guia_portao_esq` (7,2), `guia_portao_dir` (0,3) |
| Portão de aço | `portao_caixa` (1,3), `portao_meio` (2,3), `portao_meio_runa` (3,3), `portao_base` (4,3), `portao_base_cadeado` (5,3), `portao_trilho_esq` (6,3), `portao_trilho_dir` (7,3) |
| Calçada portuguesa | `calcada_onda_1` (0,4), `calcada_onda_2` (1,4), `calcada_onda_3` (2,4), `calcada_onda_4` (3,4), `calcada_lisa` (4,4), `meio_fio` (5,4) |
| Grama (lado de fora) | `grama_a` (6,4), `grama_b` (7,4), `grama_flor` (0,5), `grama_tufo` (1,5) |
| Sombra (sobreposição) | `sombra_topo` (2,5), `sombra_esq` (3,5), `sombra_dir` (4,5), `sombra_canto_esq` (5,5), `sombra_canto_dir` (6,5) |
| Decoração (sobreposição) | `teia_esq` (7,5), `teia_dir` (0,6), `cogumelos_roxos` (1,6), `rachadura_chao` (2,6), `ralo` (3,6), `mancha` (4,6), `caveirinha` (5,6), `runa_chao` (6,6), `runa_parede` (7,6), `rachadura_parede` (0,7) |
As linhas "Sombra" e "Decoração" são transparentes e ficam por cima do piso ou da parede.
O portão de aço fechado é montado com `portao_trilho_esq` + `portao_caixa` (linha de cima), `portao_meio` / `portao_meio_runa` (meio), `portao_base` / `portao_base_cadeado` (embaixo) e `portao_trilho_dir`.

## Mini games — fundos (pixel 2x: desenhados em metade do tamanho, Sprite2D com scale 2)

| Cena | Nó | Arte |
|---|---|---|
| `minigame/carne_sol/carne_sol.tscn` | `Chao` (Sprite2D) | `carne_sol/art/fundo_carne_sol.png` (320x180) |
| `minigame/macaxeira_manteiga/macaxeira_manteiga.tscn` | `Chao` (Sprite2D) | `macaxeira_manteiga/art/fundo_macaxeira.png` (320x180) |
| `minigame/farofa_tanajura/farofa_tanajura.tscn` | `Chao` (Sprite2D, z −20, pos −20,−20) | `farofa_tanajura/art/fundo_arena.png` (340x200: sobra 20 px para a tremida de tela) |
| `minigame/comum/salao_vip.tscn` | `Cenario` (Sprite2D, z −50, pos −60,−40) | `comum/art/fundo_salao_vip.png` (380x220: cobre a área toda da câmera) |

Salão: a porta está desenhada no fundo. `Fundo/Porta/Aberta` (usada pela abertura do VIP) continua lá e cobre a folha da porta quando ela abre. `Fundo` e `Porta` ficaram transparentes, só para manter o caminho do nó.
