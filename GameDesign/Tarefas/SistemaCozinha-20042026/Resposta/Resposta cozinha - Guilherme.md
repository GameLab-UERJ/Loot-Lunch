# Proposta de Design: Sistema de Cozinha (Churrasco)

**Autor(a):** Guilherme Linhares 
**Data:** 27/05/2026

## 1. Visão Geral do Ciclo (Core Loop)
*Descreva brevemente como o jogador entra no modo restaurante, prepara o churrasco e finaliza o dia.*

> Ao entrar na cidade esqueleto, o jogador tem suas habilidades e ataques desabilitados. Com isso, sua lista de comandos muda para uma versão alternativa, voltada para interação com os esqueletos, objetos importantes e sistemas da cidade.

Dentro do restaurante, a cozinha é o ponto onde o jogador utiliza os ingredientes encontrados na masmorra para preparar receitas. Nesta primeira interação, o foco será o preparo de churrascos feitos com carnes de monstros.

O preparo do churrasco pode funcionar por meio de mini-games rápidos, simples e intuitivos, com duração média de 10 a 20 segundos por prato.

Exemplo:

    Clicar no momento certo para cortar a carne.
    Controlar o ponto certo de virar o espeto.
    Ajustar rapidamente a intensidade da brasa.
    Retirar a carne da grelha antes que passe do ponto.
    Mover o analógico ou mouse em círculos para misturar molhos ou temperos.
    Escolher temperos que combinem com o tipo de carne.

A grelha pode ter uma barra de ponto da carne, indo de cru até queimado. O jogador precisa prestar atenção ao tempo certo para virar e retirar o churrasco. Quanto melhor o timing, maior a qualidade final do prato.

Ao final do expediente, o jogador recebe recompensas, feedbacks dos esqueletos e possíveis indicações de novos ingredientes ou pratos para buscar na masmorra.

## 2. Mecânica de Cozimento: O Churrasco de Monstro
*Como o jogador interage com o preparo? Detalhe os controles, a tela e o desafio (ex: apertar botão no tempo certo, gerenciar a altura da grelha).*

> A mecânica de cozimento deve ser simples, mas ainda assim interativa. Jogos como Genshin Impact possuem sistemas de culinária simples e eficientes, enquanto jogos de simulação de taverna costumam apresentar sistemas mais complexos, mas igualmente interessantes. A proposta é trabalhar em um meio-termo.

O jogador não deve ser obrigado a preparar o mesmo prato manualmente muitas vezes para sempre. Após fazer uma receita um número determinado de vezes, ele adquire maestria nela, podendo prepará-la automaticamente ou com uma versão simplificada do processo.

Até adquirir maestria, o preparo deve ser feito manualmente. Cada prato não deve demorar mais que 10 a 20 segundos para ser preparado. Os mini-games precisam ser simples e intuitivos, como clicar no momento certo para cortar a carne, mover o analógico ou mouse em círculos para misturar uma panela, virar o espeto no tempo correto ou controlar rapidamente a brasa.

O jogador também poderá modificar o prato por meio dos temperos. Esses temperos concedem bônus e alteram valores de sabor, como:

    Salgado, azedo, ácido, doce, umami.

O umami funcionaria como um sabor especial, quase como um coringa. Entregar pratos que combinem esses valores de forma lógica aumenta a qualidade da comida, melhora a satisfação dos esqueletos e gera feedbacks mais positivos.

## 3. Mecânica de Gerenciamento do Salão
*Como os esqueletos interagem com o restaurante? Como entregamos a comida e recebemos as recompensas?*

> Inicialmente, o jogador estará sozinho no restaurante. Isso significa que ele precisará fazer a comida, servir os clientes e coletar as recompensas por conta própria.

No começo, essa rotina pode parecer muita coisa (e a intenção é justamente essa). O restaurante deve começar com uma sensação de "ambiente caótico", fazendo o jogador sentir que administrar tudo sozinho é trabalhoso.

Com o decorrer do jogo, o jogador poderá recrutar novos funcionários e aliados para ajudar no restaurante. Com isso, o estabelecimento começa a ser automatizado aos poucos.

Eventualmente, os esqueletos deixarão feedbacks para o jogador, comentando sobre os temperos, os pratos que gostariam de comer, pedidos especiais, reclamações e piadas. Esses comentários podem seguir uma lógica parecida com os feedbacks do bandeijão UERJ, trazendo humor e personalidade para os clientes.

As recompensas podem vir tanto dos pagamentos dos clientes quanto dos feedbacks positivos, que funcionam como uma forma de progressão do restaurante e do jogador.

## 4. O Fator Diversão (O que faz isso ser legal?)
*Por que o jogador vai querer voltar da masmorra para fazer churrasco? Qual é o "suco" (game feel) dessa mecânica?*

> O fator principal de diversão está nos feedbacks e no ciclo entre masmorra e restaurante.

O jogador entra na masmorra, derrota monstros, coleta ingredientes, volta para cidade esqueleto, prepara receitas, serve os esqueletos e recebe recompensas. Depois disso, os feedbacks dos clientes indicam novas vontades, reclamações, piadas ou pedidos especiais, criando novos objetivos para a próxima exploração.

Tudo pode ser entregue pelo diário do restaurante, que registra os comentários dos esqueletos e transforma esses feedbacks em progresso.

Cada comentário positivo pode conceder um microbuff ou algum tipo de avanço, quase como o sistema de evolução de Hades, onde o jogador compra melhorias no quarto do protagonista. Porém, nesse caso, a “compra” ocorre por meio do preparo dos pratos e da coleta dos feedbacks.

## 5. Integração com o Loot
*Como os drops específicos da masmorra (ex: Carne de Fera-Pavão do 2º Andar) afetam o preparo ou o resultado do prato?*

> Acredito que o caminho ideal seja fazer com que cada mob sempre tenha um item específico de drop, permitindo que o jogador prepare um prato próprio a partir daquele ingrediente.

Esse sistema seria parecido com o sistema de poções de The Witcher 3, em que o jogador coleta itens e cria poções específicas ligadas a determinados monstros. No caso do restaurante, esses itens seriam transformados em receitas.

Por exemplo, uma Fera-Pavão do 2º andar poderia dropar uma carne específica, usada para preparar um churrasco exclusivo. Esse prato poderia ter sabor, dificuldade de preparo e feedbacks próprios.

Para mim, a forma mais eficiente de alterar o resultado do preparo é por meio de dois fatores:

    O desempenho do jogador nos mini-games, que define o nível de qualidade do prato.
    O uso dos temperos, que altera os sabores e permite combinações mais complexas.

Além disso, alguns ingredientes ou temperos mais raros podem estar ligados a mobs específicos, bosses, quests ou eventos especiais. Isso cria motivos para o jogador voltar à masmorra em busca de determinados monstros e materiais.