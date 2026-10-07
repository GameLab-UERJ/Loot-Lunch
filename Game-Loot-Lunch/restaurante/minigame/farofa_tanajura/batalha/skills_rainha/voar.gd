extends FormigaSkill
## VOAR (Rainha): ela bate as asas e SOBE. No céu:
##   - golpes corpo a corpo não alcançam (só a Besta);
##   - ela não ataca (a espera dela para) e desce sozinha depois de `flight_time`;
##   - as formigas pequenas entram em FÚRIA: a batalha dobra o dano delas.
## Uma flechada da Besta derruba e as asas devolvem a mana TODA do chef
## (QueenAntBattler.on_ranged_hit).


func can_use(_battle: TurnBattle, ant: FormigaBattler) -> bool:
	var queen := ant as QueenAntBattler
	return queen != null and not queen.airborne


func _execute(battle: TurnBattle, ant: FormigaBattler, _chef: ChefBattler) -> void:
	var queen := ant as QueenAntBattler
	await queen.squash(Vector2(1.2, 0.8), 0.25)
	battle.shake(2.0, 0.2)
	await queen.fly_up()
