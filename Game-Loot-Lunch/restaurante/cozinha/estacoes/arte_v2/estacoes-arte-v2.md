# Arte v2 das estações

Tudo dentro de `res://restaurante/cozinha/estacoes/arte_v2/`. Mesmo estilo do tileset v2: contorno `#2B1D0E` do chef e o roxo das runas da churrasqueira. **Não testado no Godot.**

## Arquivos

| Arquivo | O que é |
|---|---|
| `cogumelo_pe.png` + `cogumelo_pe_frames.tres` | Pé de cogumelo, quadros de 32x40. Linhas: idle (6), corte (7), regenerando (8), vazio (1). |
| `raiz_espeto.png` + `raiz_espeto_frames.tres` | Raiz de espeto, quadros de 32x40, com as mesmas 4 animações. |
| `mesa_carne.png` | Mesa de carne, 32x32. Substitui a caixa de carne. |
| `mesa_corte.png` | Mesa de corte, 32x32. A tábua já vem embutida na mesa e substitui a tábua solta. |
| `previews/*.gif` | Cada animação em 4x. |
| `previews/cozinha_com_estacoes_v2.png` | Cozinha compacta já com as estações novas. |

Os quadros têm 40 px de altura para o chapéu e o espeto terem espaço para voar no corte. O chão do desenho fica em y = 37. Se o nó estava alinhado pelo centro de um quadro de 32 px, use `AnimatedSprite2D.offset = Vector2(0, -4)`.

## Animações (SpriteFrames)

| Nome | Loop | Velocidade | Quando tocar |
|---|---|---|---|
| `idle` | sim | 6 fps | Pronto para coletar: brilho pulsando e esporos ou faíscas flutuando. |
| `corte` | não | 12 fps | Na hora em que o chef pega o item. Termina no toco. |
| `regenerando` | não | 1,6 fps no cogumelo (8 quadros em 5 s), 2,67 fps na raiz (8 quadros em 3 s) | Durante o cooldown. A velocidade é `8 / duração`. Ajuste se mudar o cooldown. |
| `vazio` | — | — | Toco parado, para usar se preferir não animar a regeneração. |

## Como ligar no jogo

O `IngredientPlant` e o `AssemblyStation` usam hoje um `Sprite2D` escurecido com `self_modulate`. Para usar a arte nova:

1. Troque o `Sprite2D` por um `AnimatedSprite2D` com o `*_frames.tres`.
2. Ao entregar o item, toque `corte`.
3. Quando o cooldown começar, toque `regenerando`. Ajuste o `speed_scale` se a duração for diferente.
4. No fim do cooldown, volte para `idle`. O escurecido do `self_modulate` deixa de ser necessário.

As mesas de carne e de corte são `Sprite2D` estáticos nas cenas `caixa_carne.tscn` e `tabua_corte.tscn`. Ajuste o `ItemSlot` da mesa de corte para o item ficar em cima da tábua embutida, mais ou menos em (−3, −6).
