extends Node

## Headless autoplay balance probe — corner defense + upgrades.


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	seed(42)
	GameState.start_game()
	# Cover track corners / mid edges (buildable cells are 1..3)
	GameState.build_unit(1, 1, "PRISM")
	GameState.build_unit(3, 1, "SPIKE")
	GameState.build_unit(1, 3, "HALO")
	var buy_plan: Array = [
		{"x": 3, "y": 3, "type": "DART"},
		{"x": 2, "y": 1, "type": "AURORA"},
		{"x": 2, "y": 3, "type": "SEEKER"},
		{"x": 1, "y": 2, "type": "APEX"},
		{"x": 3, "y": 2, "type": "RAIL"},
		{"x": 2, "y": 2, "type": "BARRAGE"},
	]
	var buy_i := 0
	GameState.time_scale = 10.0

	var frames := 0
	var max_frames := 25000
	while GameState.game_over == "" and frames < max_frames:
		# Spend on upgrades first
		if GameState.gold >= 24:
			var upgraded := false
			for u in GameState.units:
				var lv := int(u["level"])
				if lv >= GameData.MAX_UNIT_LEVEL:
					continue
				var cost := int(GameData.get_unit(str(u["type"]))["cost"]) * lv
				if GameState.gold >= cost:
					GameState.upgrade_unit(int(u["x"]), int(u["y"]))
					upgraded = true
					break
			if not upgraded and buy_i < buy_plan.size():
				var step: Dictionary = buy_plan[buy_i]
				var def: Dictionary = GameData.get_unit(str(step["type"]))
				if GameState.gold >= int(def["cost"]):
					var before := GameState.units.size()
					GameState.build_unit(int(step["x"]), int(step["y"]), str(step["type"]))
					if GameState.units.size() > before:
						buy_i += 1
		for _j in 6:
			await get_tree().process_frame
		frames += 6

	var phase := GameState.get_current_phase()
	print("BALANCE: result=%s kills=%d bosses=%d gold=%d units=%d monsters=%d wave=%s time=%.1f frames=%d" % [
		GameState.game_over if GameState.game_over != "" else "timeout",
		GameState.kills,
		GameState.boss_kills,
		GameState.gold,
		GameState.units.size(),
		GameState.monsters.size(),
		str(phase.get("wave", "?")),
		GameState.time_remaining,
		frames,
	])
	get_tree().quit(0)
