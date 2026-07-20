extends RefCounted
class_name GameData

## Ported from React src/data + useGameEngine constants

const MAX_MONSTERS := 99
const MAX_UNIT_LEVEL := 3

const FACTIONS := {
	"LUMINA": {"id": "LUMINA", "name": "Lumina", "color": Color("#38bdf8")},
	"VECTRA": {"id": "VECTRA", "name": "Vectra", "color": Color("#f97316")},
	"FERRUM": {"id": "FERRUM", "name": "Ferrum", "color": Color("#94a3b8")},
}

const UNIT_TYPES := {
	"PRISM": {
		"type": "PRISM", "faction": "LUMINA", "name": "Prism", "icon": "◇",
		"blurb": "광역 · 사거리 3",
		"cost": 10, "sight": 3.0, "damage": 2.0, "attack_cooldown": 0.95,
		"attack_mode": "splash", "splash_range": 1.2, "target_mode": "nearest",
	},
	"HALO": {
		"type": "HALO", "faction": "LUMINA", "name": "Halo", "icon": "◎",
		"blurb": "넓은 광역 · 사거리 2.5",
		"cost": 14, "sight": 2.5, "damage": 1.8, "attack_cooldown": 1.0,
		"attack_mode": "splash", "splash_range": 1.9, "target_mode": "nearest",
	},
	"AURORA": {
		"type": "AURORA", "faction": "LUMINA", "name": "Aurora", "icon": "✧",
		"blurb": "장거리 광역 · 사거리 4",
		"cost": 18, "sight": 4.0, "damage": 1.6, "attack_cooldown": 1.15,
		"attack_mode": "splash", "splash_range": 1.6, "target_mode": "nearest",
	},
	"DART": {
		"type": "DART", "faction": "VECTRA", "name": "Dart", "icon": "▸",
		"blurb": "빠른 광역 · 사거리 2",
		"cost": 12, "sight": 2.2, "damage": 3.4, "attack_cooldown": 0.9,
		"attack_mode": "splash", "splash_range": 1.1, "target_mode": "nearest",
	},
	"SEEKER": {
		"type": "SEEKER", "faction": "VECTRA", "name": "Seeker", "icon": "◈",
		"blurb": "유도 광역 · 사거리 2.5",
		"cost": 16, "sight": 2.6, "damage": 4.0, "attack_cooldown": 1.05,
		"attack_mode": "splash", "splash_range": 1.15, "target_mode": "nearest",
		"homing": true,
	},
	"BARRAGE": {
		"type": "BARRAGE", "faction": "VECTRA", "name": "Barrage", "icon": "⫷",
		"blurb": "다발 광역 · 사거리 2",
		"cost": 20, "sight": 2.2, "damage": 3.2, "attack_cooldown": 1.25,
		"attack_mode": "splash", "splash_range": 1.7, "target_mode": "nearest",
	},
	"SPIKE": {
		"type": "SPIKE", "faction": "FERRUM", "name": "Spike", "icon": "▲",
		"blurb": "단일 고화력 · 사거리 2.5",
		"cost": 12, "sight": 2.5, "damage": 9.0, "attack_cooldown": 0.95,
		"attack_mode": "single", "target_mode": "nearest",
	},
	"APEX": {
		"type": "APEX", "faction": "FERRUM", "name": "Apex", "icon": "⬢",
		"blurb": "최강 타겟 · 사거리 3",
		"cost": 18, "sight": 3.0, "damage": 14.0, "attack_cooldown": 1.8,
		"attack_mode": "single", "target_mode": "strongest",
	},
	"RAIL": {
		"type": "RAIL", "faction": "FERRUM", "name": "Rail", "icon": "━",
		"blurb": "장거리 스나이핑 · 사거리 4",
		"cost": 22, "sight": 4.0, "damage": 18.0, "attack_cooldown": 2.5,
		"attack_mode": "single", "target_mode": "strongest",
	},
}

const UNIT_KEYS_BY_FACTION := {
	"LUMINA": ["PRISM", "HALO", "AURORA"],
	"VECTRA": ["DART", "SEEKER", "BARRAGE"],
	"FERRUM": ["SPIKE", "APEX", "RAIL"],
}

## Internal type keys kept for saves/sim; display names are cyber-threat themed.
const NORMAL_MONSTERS := [
	{
		"type": "GOBLIN", "name": "Spore", "name_ko": "스포어",
		"hp_base": 11.0, "hp_scale": 3.5, "speed": 0.9, "reward": 3,
		"color": Color("#34d399"),
	},
	{
		"type": "ORC", "name": "Assault", "name_ko": "어썰트",
		"hp_base": 18.0, "hp_scale": 6.0, "speed": 0.7, "reward": 4,
		"color": Color("#fb923c"),
	},
	{
		"type": "WOLF", "name": "Skimmer", "name_ko": "스키머",
		"hp_base": 9.0, "hp_scale": 3.0, "speed": 1.35, "reward": 3,
		"color": Color("#94a3b8"),
	},
]

const BOSS_MONSTERS := [
	{
		"type": "GOLEM", "name": "Bastion", "name_ko": "배스천",
		"hp_base": 120.0, "hp_scale": 35.0, "speed": 0.8, "reward": 30,
		"color": Color("#a78bfa"),
	},
	{
		"type": "DRAGON", "name": "Wyrm", "name_ko": "와름",
		"hp_base": 240.0, "hp_scale": 55.0, "speed": 0.95, "reward": 60,
		"color": Color("#f87171"),
	},
	{
		"type": "DEMON", "name": "Reaper", "name_ko": "리퍼",
		"hp_base": 360.0, "hp_scale": 70.0, "speed": 1.05, "reward": 100,
		"color": Color("#dc2626"),
	},
]

## Max normal spawns per combat wave (1..5). Bosses spawn separately.
const SPAWNS_PER_WAVE := [0, 12, 15, 18, 20, 10]
const SPAWN_INTERVAL := 1.5

## Track path (16 cells around the rim)
const TRACK_PATH := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4),
	Vector2i(3, 4), Vector2i(2, 4), Vector2i(1, 4), Vector2i(0, 4),
	Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1),
]

const TIMELINE := [
	{"duration": 28.0, "type": "COMBAT", "wave": 1},
	{"duration": 8.0, "type": "REST", "wave": 1},
	{"duration": 32.0, "type": "COMBAT", "wave": 2},
	{"duration": 9.0, "type": "REST", "wave": 2},
	{"duration": 36.0, "type": "COMBAT", "wave": 3},
	{"duration": 10.0, "type": "REST", "wave": 3},
	{"duration": 40.0, "type": "COMBAT", "wave": 4},
	{"duration": 12.0, "type": "REST", "wave": 4},
	{"duration": 45.0, "type": "COMBAT", "wave": 5},
]

static func total_duration() -> float:
	var sum := 0.0
	for p in TIMELINE:
		sum += float(p["duration"])
	return sum


static func get_unit(type_key: String) -> Dictionary:
	return UNIT_TYPES.get(type_key, {})


static func get_monster(type_key: String) -> Dictionary:
	for m in NORMAL_MONSTERS:
		if str(m["type"]) == type_key:
			return m
	for m in BOSS_MONSTERS:
		if str(m["type"]) == type_key:
			return m
	return {}


static func monster_display_name(type_key: String, korean: bool = true) -> String:
	var m := get_monster(type_key)
	if m.is_empty():
		return type_key
	if korean and m.has("name_ko"):
		return str(m["name_ko"])
	return str(m.get("name", type_key))
