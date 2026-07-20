extends Node

## Ported from useGameEngine.js — simulation + signals for UI

signal state_changed
signal game_started
signal game_over_changed(result: String)
signal attack_fired(mode: String, faction: String)
signal unit_built(type_key: String)
signal monster_killed(is_boss: bool)
signal monster_died_at(x: float, y: float, is_boss: bool)
signal boss_spawned(type_key: String, is_final: bool)
signal gold_gained_at(x: float, y: float, amount: int)
signal drag_changed
signal phase_changed(phase_type: String, wave: int)

var enabled: bool = false
var paused: bool = false
var time_scale: float = 1.0
var selected_action: String = "" # "UPGRADE", "SELL", or "" (units use drag)
var drag_unit_type: String = ""
var faction_tab: String = "LUMINA"

var gold: int = 50
var monsters: Array = []
var units: Array = []
var attacks: Array = []
var time_remaining: float = 0.0
var game_over: String = "" # "", "win", "lose"
var kills: int = 0
var boss_kills: int = 0

var _next_id: int = 1
var _last_spawn_time: float = 0.0
var _spawned_in_wave: int = 0
var _boss_spawned_for_wave: bool = false
var _elapsed_time: float = 0.0 # seconds since enable, for spawn timing
var _ui_emit_accum: float = 0.0
var _last_phase_key: String = ""
const UI_EMIT_INTERVAL := 1.0 / 10.0 # HUD only; board renders every frame


func _ready() -> void:
	time_remaining = GameData.total_duration()
	set_process(false)


func _emit_ui(force: bool = false) -> void:
	if force:
		_ui_emit_accum = 0.0
		state_changed.emit()
		return
	# Throttled from _process; caller manages accumulator


func start_game() -> void:
	_reset_sim()
	enabled = true
	set_process(true)
	_last_spawn_time = 0.0
	_elapsed_time = 0.0
	game_started.emit()
	_emit_ui(true)


func restart_game() -> void:
	start_game()


func return_to_title() -> void:
	enabled = false
	set_process(false)
	_reset_sim()
	clear_unit_drag()
	_emit_ui(true)


func set_selected_action(action: String) -> void:
	drag_unit_type = ""
	if selected_action == action:
		selected_action = ""
	else:
		selected_action = action
	drag_changed.emit()
	_emit_ui(true)


func begin_unit_drag(type_key: String) -> bool:
	if game_over != "" or not enabled:
		return false
	var type_def: Dictionary = GameData.get_unit(type_key)
	if type_def.is_empty() or gold < int(type_def["cost"]):
		return false
	selected_action = ""
	drag_unit_type = type_key
	drag_changed.emit()
	_emit_ui(true)
	return true


func clear_unit_drag() -> void:
	if drag_unit_type == "":
		return
	drag_unit_type = ""
	drag_changed.emit()
	_emit_ui(true)


func try_drop_unit(x: int, y: int) -> bool:
	if drag_unit_type == "":
		return false
	var type_key := drag_unit_type
	var before := units.size()
	build_unit(x, y, type_key)
	var ok := units.size() > before
	clear_unit_drag()
	return ok


func set_faction_tab(faction: String) -> void:
	faction_tab = faction
	_emit_ui(true)


func on_cell_pressed(x: int, y: int) -> void:
	if game_over != "":
		return
	var is_track := x == 0 or x == 4 or y == 0 or y == 4
	if is_track:
		return
	if drag_unit_type != "":
		try_drop_unit(x, y)
		return
	if selected_action == "SELL":
		sell_unit(x, y)
	elif selected_action == "UPGRADE":
		upgrade_unit(x, y)


func build_unit(x: int, y: int, type_key: String) -> void:
	if game_over != "":
		return
	var type_def: Dictionary = GameData.get_unit(type_key)
	if type_def.is_empty() or gold < int(type_def["cost"]):
		return
	for u in units:
		if int(u["x"]) == x and int(u["y"]) == y:
			return
	gold -= int(type_def["cost"])
	units.append({
		"id": _alloc_id(),
		"x": x,
		"y": y,
		"type": type_def["type"],
		"faction": type_def["faction"],
		"last_attack_time": 0.0,
		"level": 1,
		"total_spent": int(type_def["cost"]),
		"has_aim": false,
		"aim_x": float(x),
		"aim_y": float(y),
		"recoil_until": 0.0,
	})
	selected_action = ""
	# keep drag clear to caller when using try_drop_unit; direct build clears drag too
	if drag_unit_type == type_key:
		drag_unit_type = ""
		drag_changed.emit()
	unit_built.emit(type_key)
	_emit_ui(true)


func upgrade_unit(x: int, y: int) -> void:
	if game_over != "":
		return
	for i in units.size():
		var u: Dictionary = units[i]
		if int(u["x"]) != x or int(u["y"]) != y:
			continue
		var cur_level := int(u["level"])
		if cur_level >= GameData.MAX_UNIT_LEVEL:
			return
		var type_def: Dictionary = GameData.get_unit(str(u["type"]))
		var cost := int(type_def["cost"]) * cur_level
		if gold < cost:
			return
		gold -= cost
		u["level"] = cur_level + 1
		u["total_spent"] = int(u["total_spent"]) + cost
		units[i] = u
		selected_action = ""
		if Sfx.has_method("play"):
			Sfx.play("upgrade")
		_emit_ui(true)
		return


func sell_unit(x: int, y: int) -> void:
	if game_over != "":
		return
	for i in units.size():
		var u: Dictionary = units[i]
		if int(u["x"]) != x or int(u["y"]) != y:
			continue
		gold += int(u["total_spent"]) / 2
		units.remove_at(i)
		selected_action = ""
		_emit_ui(true)
		return


func get_current_phase() -> Dictionary:
	var elapsed := GameData.total_duration() - time_remaining
	for p in GameData.TIMELINE:
		var dur := float(p["duration"])
		if elapsed < dur:
			var out: Dictionary = p.duplicate()
			out["time_in_phase"] = elapsed
			return out
		elapsed -= dur
	return {"type": "END", "wave": 5, "time_in_phase": 0.0, "duration": 0.0}


func get_elapsed_time() -> float:
	return _elapsed_time


func get_monster_position(progress: float) -> Vector2:
	var clamped := clampf(progress, 0.0, 15.999)
	var index := int(floor(clamped))
	var next_index := mini(index + 1, 15)
	var fraction := clamped - float(index)
	var p1: Vector2i = GameData.TRACK_PATH[index]
	var p2: Vector2i = GameData.TRACK_PATH[next_index]
	return Vector2(
		float(p1.x) + float(p2.x - p1.x) * fraction,
		float(p1.y) + float(p2.y - p1.y) * fraction
	)


func toggle_pause() -> void:
	if not enabled or game_over != "":
		return
	paused = not paused
	state_changed.emit()


func toggle_speed() -> void:
	time_scale = 2.0 if time_scale < 1.5 else 1.0
	_emit_ui(true)


func _process(delta: float) -> void:
	if not enabled or game_over != "" or paused:
		return
	var dt := minf(delta, 0.05) * time_scale
	_elapsed_time += dt

	time_remaining -= dt
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_set_game_over("win")
		return

	# 1. Move monsters
	var next_monsters: Array = []
	for m in monsters:
		var nm: Dictionary = m.duplicate()
		nm["progress"] = float(m["progress"]) + float(m["speed"]) * dt
		next_monsters.append(nm)

	if next_monsters.size() > GameData.MAX_MONSTERS:
		monsters = next_monsters
		_set_game_over("lose")
		return
	for m in next_monsters:
		if float(m["progress"]) >= 16.0:
			monsters = next_monsters
			_set_game_over("lose")
			return

	var monsters_with_pos: Array = []
	for m in next_monsters:
		var mp: Dictionary = m.duplicate()
		var pos := get_monster_position(float(m["progress"]))
		mp["mx"] = pos.x
		mp["my"] = pos.y
		monsters_with_pos.append(mp)

	# 2. Attacks
	var now_time := _elapsed_time
	var new_attacks: Array = []
	var next_attacks: Array = []
	for a in attacks:
		if now_time - float(a["time"]) < 0.55:
			next_attacks.append(a)

	var next_units: Array = []
	for unit in units:
		var u: Dictionary = unit.duplicate()
		var type_def: Dictionary = GameData.get_unit(str(u["type"]))
		if type_def.is_empty():
			next_units.append(u)
			continue

		var best: Dictionary = {}
		var sight_range := float(type_def["sight"]) * sqrt(2.0)
		if str(type_def["target_mode"]) == "strongest":
			var max_hp := -1.0
			for m in monsters_with_pos:
				var dist := _dist(float(u["x"]), float(u["y"]), float(m["mx"]), float(m["my"]))
				if dist <= sight_range and float(m["hp"]) > max_hp:
					max_hp = float(m["hp"])
					best = m
		else:
			var min_d := INF
			for m in monsters_with_pos:
				var dist := _dist(float(u["x"]), float(u["y"]), float(m["mx"]), float(m["my"]))
				if dist <= sight_range and dist < min_d:
					min_d = dist
					best = m

		# Always track aim for smooth turret turn (Clash-style)
		if not best.is_empty():
			u["aim_x"] = float(best["mx"])
			u["aim_y"] = float(best["my"])
			u["has_aim"] = true
		else:
			u["has_aim"] = false

		if best.is_empty() or now_time - float(u["last_attack_time"]) < float(type_def["attack_cooldown"]):
			next_units.append(u)
			continue

		var level := int(u["level"])
		var dmg := float(type_def["damage"]) * float(level)
		if str(type_def["attack_mode"]) == "splash":
			var splash_range := float(type_def.get("splash_range", 1.5))
			for i in next_monsters.size():
				var m: Dictionary = next_monsters[i]
				var pos_m: Dictionary = {}
				for p in monsters_with_pos:
					if int(p["id"]) == int(m["id"]):
						pos_m = p
						break
				if pos_m.is_empty():
					continue
				if _dist(float(best["mx"]), float(best["my"]), float(pos_m["mx"]), float(pos_m["my"])) <= splash_range:
					m["hp"] = float(m["hp"]) - dmg
					m["flash_until"] = now_time + 0.12
					next_monsters[i] = m
			new_attacks.append({
				"id": _alloc_id(),
				"mode": "splash",
				"faction": type_def["faction"],
				"unit_type": u["type"],
				"tx": best["mx"],
				"ty": best["my"],
				"time": now_time,
			})
			attack_fired.emit("splash", str(type_def["faction"]))
		else:
			for i in next_monsters.size():
				var m: Dictionary = next_monsters[i]
				if int(m["id"]) == int(best["id"]):
					m["hp"] = float(m["hp"]) - dmg
					m["flash_until"] = now_time + 0.12
					next_monsters[i] = m
					break
			new_attacks.append({
				"id": _alloc_id(),
				"mode": "single",
				"faction": type_def["faction"],
				"unit_type": u["type"],
				"homing": type_def.get("homing", false),
				"sx": u["x"],
				"sy": u["y"],
				"tx": best["mx"],
				"ty": best["my"],
				"time": now_time,
			})
			attack_fired.emit("single", str(type_def["faction"]))

		u["last_attack_time"] = now_time
		u["recoil_until"] = now_time + 0.08
		next_units.append(u)

	# 3. Remove dead
	var gold_gained := 0
	var final_boss_killed := false
	var surviving: Array = []
	for m in next_monsters:
		if float(m["hp"]) <= 0.0:
			var reward := int(m.get("reward", 2))
			gold_gained += reward
			kills += 1
			if bool(m.get("is_boss", false)):
				boss_kills += 1
			monster_killed.emit(bool(m.get("is_boss", false)))
			var death_pos := get_monster_position(float(m["progress"]))
			monster_died_at.emit(death_pos.x, death_pos.y, bool(m.get("is_boss", false)))
			gold_gained_at.emit(death_pos.x, death_pos.y, reward)
			if m.get("is_final_boss", false):
				final_boss_killed = true
		else:
			surviving.append(m)

	monsters = surviving
	units = next_units
	attacks = next_attacks + new_attacks
	if gold_gained > 0:
		gold += gold_gained

	if final_boss_killed:
		_set_game_over("win")
		return

	# 4. Spawn
	var phase := get_current_phase()
	var phase_key := "%s_%s" % [str(phase["type"]), str(phase["wave"])]
	if phase_key != _last_phase_key:
		_last_phase_key = phase_key
		_spawned_in_wave = 0
		_last_spawn_time = _elapsed_time
		if str(phase["type"]) == "COMBAT":
			_boss_spawned_for_wave = false
		phase_changed.emit(str(phase["type"]), int(phase["wave"]))
	if str(phase["type"]) == "COMBAT":
		var wave := int(phase["wave"])
		var spawn_cap: int = GameData.SPAWNS_PER_WAVE[mini(wave, GameData.SPAWNS_PER_WAVE.size() - 1)]
		if _spawned_in_wave < spawn_cap and (_elapsed_time - _last_spawn_time) >= GameData.SPAWN_INTERVAL:
			_spawn_monster(wave, false, -1, false)
			_last_spawn_time = _elapsed_time
			_spawned_in_wave += 1
		# Boss at ~35% into combat (not instantly)
		var tip := float(phase["time_in_phase"])
		var boss_at := float(phase.get("duration", 30.0)) * 0.35
		if not _boss_spawned_for_wave and tip >= boss_at:
			if wave == 2:
				_spawn_monster(2, true, 0, false)
				_boss_spawned_for_wave = true
			elif wave == 4:
				_spawn_monster(4, true, 1, false)
				_boss_spawned_for_wave = true
			elif wave == 5:
				_spawn_monster(5, true, 2, true)
				_boss_spawned_for_wave = true
	elif str(phase["type"]) == "REST":
		_boss_spawned_for_wave = false

	_ui_emit_accum += dt
	if _ui_emit_accum >= UI_EMIT_INTERVAL:
		_ui_emit_accum = 0.0
		state_changed.emit()


func _spawn_monster(wave: int, is_boss: bool, boss_index: int, is_final_boss: bool) -> void:
	var template: Dictionary
	if is_boss:
		var idx := boss_index if boss_index >= 0 else mini(wave - 1, GameData.BOSS_MONSTERS.size() - 1)
		idx = mini(idx, GameData.BOSS_MONSTERS.size() - 1)
		template = GameData.BOSS_MONSTERS[idx]
	else:
		var max_normal := mini(wave, GameData.NORMAL_MONSTERS.size())
		var normal_index := randi() % max_normal
		template = GameData.NORMAL_MONSTERS[normal_index]

	var hp := float(template["hp_base"]) + float(template["hp_scale"]) * float(wave - 1)
	var type_key := str(template["type"])
	monsters.append({
		"id": _alloc_id(),
		"progress": 0.0,
		"hp": hp,
		"max_hp": hp,
		"speed": float(template["speed"]),
		"reward": int(template["reward"]),
		"color": template["color"],
		"is_boss": is_boss,
		"is_final_boss": is_final_boss,
		"type": type_key,
		"flash_until": 0.0,
	})
	if is_boss:
		boss_spawned.emit(type_key, is_final_boss)


func _set_game_over(result: String) -> void:
	game_over = result
	_emit_ui(true)
	game_over_changed.emit(result)


func _reset_sim() -> void:
	monsters = []
	units = []
	attacks = []
	gold = 50
	time_remaining = GameData.total_duration()
	game_over = ""
	paused = false
	time_scale = 1.0
	kills = 0
	boss_kills = 0
	_last_phase_key = ""
	_next_id = 1
	_last_spawn_time = 0.0
	_spawned_in_wave = 0
	_boss_spawned_for_wave = false
	_elapsed_time = 0.0
	selected_action = ""
	drag_unit_type = ""
	faction_tab = "LUMINA"


func _alloc_id() -> int:
	var id := _next_id
	_next_id += 1
	return id


func _dist(ax: float, ay: float, bx: float, by: float) -> float:
	return Vector2(ax, ay).distance_to(Vector2(bx, by))
