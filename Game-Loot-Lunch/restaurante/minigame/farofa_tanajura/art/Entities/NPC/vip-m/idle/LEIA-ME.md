# Arte do Cliente VIP (idle)

Coloque aqui a sprite de referência do VIP:

    jscoutinho_idle_VIP_34F.png

Padrão igual ao do chef (`restaurante/personagens/chef/art/jscoutinho_idle_L_34F.png`):
tira horizontal de quadros QUADRADOS (ex.: 4 quadros de 32x32 = 128x32), olhando para a
DIREITA. O `VipNpc` (entrega_vip/vip_npc.gd) carrega o arquivo sozinho; enquanto ele não
existir, a cena da entrega usa uma arte provisória tingida de dourado e avisa no Output.
