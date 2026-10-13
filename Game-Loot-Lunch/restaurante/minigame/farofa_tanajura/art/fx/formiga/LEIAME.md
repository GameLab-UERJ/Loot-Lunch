# Formiga — padrão da luta (à DIREITA, olhando para a ESQUERDA)
Importar com filtro Nearest. Quadros na horizontal.

| Arquivo | Quadro | Qtd | Uso |
|---|---|---|---|
| Entities/formiga/tanajura_L_6F.png | 92×92 | 6 | formiga andando, olhando p/ esquerda (~5 FPS) |
| Entities/formiga/dropTanajura.png | 92×92 | 1 | drop |
| investida/investida_poeira.png | 32×32 | 6 | poeira atrás da formiga (já espelhada) |
| terremoto/terremoto_onda.png | 96×64 | 8 | onda curta (raio 44) |
| terremoto/terremoto_onda_longa.png | 256×112 | 10 | onda que alcança o player (raio 120) |
| lancar_pedra/pedra_projetil.png | 16×16 | 4 | pedra girando (loop) |
| lancar_pedra/pedra_quebrando.png | 40×40 | 6 | pedra quebrando |
| cavar/cavar_buraco.png | 32×32 | 5 | 0 monte · 1 aberto · 2-3 tremendo (dica) · 4 seleção |
| cavar/cavar_erupcao.png | 48×48 | 7 | terra explodindo ao entrar/sair |
| qte/alerta_qte.png | 16×24 | 4 | "!" de aviso (loop) |
| qte/estrelas_tonto.png | 24×12 | 4 | formiga atordoada (loop) |

Afundar/subir no buraco: recorte o sprite por baixo (shader ou region) enquanto toca cavar_erupcao.
