extends Node

signal changed

const GameDataSource = preload("res://data/GameData.gd")

const INITIAL_DAY: int = 1
const INITIAL_MONEY: int = 300
const INITIAL_HELL_TRUST: int = 50
const INITIAL_HUMAN_REPUTATION: int = 10
const INITIAL_HYGIENE: int = 70
const INITIAL_ILLEGAL_RISK: int = 0
const STAFF_SELECTION_LIMIT: int = 2
const GEAR_SELECTION_LIMIT: int = 2

const FIELD_CONTRACTS: Array[Dictionary] = [
	{
		"id": "sewer_recovery",
		"title": "버려진 하수 던전",
		"client": "마왕성 시설관리과",
		"location": "하수 처리 던전 B-12",
		"summary": "용사 파티가 지나간 뒤 오염된 하수 던전을 복구합니다.",
		"primary_stat": "cleanup",
		"difficulty": 2,
		"reward": {
			"money": 75,
			"hell_trust": 6,
			"human_reputation": 1,
			"hygiene": 7,
			"illegal_risk": 1
		},
		"tasks": [
			{
				"id": "SlimePuddle",
				"label": "끈적 점액",
				"action": "소독 점액통으로 바닥을 닦았습니다.",
				"kind": "slime",
				"primary_stat": "pollution",
				"field_position": Vector2(420, 370),
				"size": Vector2(140, 82)
			},
			{
				"id": "HolyResidue",
				"label": "성수 잔류",
				"action": "중화 분말로 성수 얼룩을 눌렀습니다.",
				"kind": "slime",
				"primary_stat": "pollution",
				"field_position": Vector2(690, 660),
				"size": Vector2(136, 74)
			},
			{
				"id": "BrokenTrap",
				"label": "망가진 함정",
				"action": "스프링과 발판을 다시 맞췄습니다.",
				"kind": "trap",
				"primary_stat": "trap",
				"field_position": Vector2(1160, 340),
				"size": Vector2(132, 72)
			},
			{
				"id": "CloggedDrain",
				"label": "막힌 배수구",
				"action": "침전물을 긁어내고 배수로를 열었습니다.",
				"kind": "rubble",
				"primary_stat": "cleanup",
				"field_position": Vector2(905, 790),
				"size": Vector2(136, 72)
			},
			{
				"id": "BonePile",
				"label": "뼈무더기",
				"action": "사체 포대에 담아 수거했습니다.",
				"kind": "bone",
				"primary_stat": "hauling",
				"field_position": Vector2(1400, 760),
				"size": Vector2(126, 80)
			},
			{
				"id": "AdventurerSatchel",
				"label": "탐사대 유품",
				"action": "소유자 표식과 반환 가능 물품을 분리했습니다.",
				"kind": "bone",
				"primary_stat": "hauling",
				"field_position": Vector2(1515, 430),
				"size": Vector2(126, 70)
			}
		],
		"combat_event": {
			"id": "sewer_holdout",
			"title": "하수 던전 잔당 진압",
			"objective": "탐사대 잔당을 제압하고 청소 작업을 재개하라",
			"label": "소란스러운 잔당",
			"action": "청소 작업을 방해하는 탐사대 잔당과 교전합니다.",
			"field_position": Vector2(1125, 735),
			"size": Vector2(132, 84),
			"settlement_bonus": {
				"money": 15,
				"hell_trust": 2,
				"human_reputation": 0,
				"hygiene": 0,
				"illegal_risk": -1
			}
		}
	},
	{
		"id": "crypt_reset",
		"title": "무너진 납골당 재정비",
		"client": "리치 회계감사실",
		"location": "고대 납골당 C-03",
		"summary": "부서진 제단과 흩어진 유해를 정리해 언데드 영업 재개를 돕습니다.",
		"primary_stat": "hauling",
		"difficulty": 3,
		"reward": {
			"money": 70,
			"hell_trust": 8,
			"human_reputation": -1,
			"hygiene": 4,
			"illegal_risk": 2
		},
		"tasks": [
			{
				"id": "AshSpill",
				"label": "흩어진 재",
				"action": "봉인 항아리에 재를 다시 담았습니다.",
				"kind": "bone",
				"position": Vector2(335, 365),
				"size": Vector2(132, 76)
			},
			{
				"id": "RubbleAltar",
				"label": "무너진 제단",
				"action": "제단 받침돌을 맞추고 균열을 메웠습니다.",
				"kind": "rubble",
				"position": Vector2(615, 300),
				"size": Vector2(150, 82)
			},
			{
				"id": "LooseBones",
				"label": "섞인 유해",
				"action": "소유자별로 유해를 분류했습니다.",
				"kind": "bone",
				"position": Vector2(900, 460),
				"size": Vector2(132, 84)
			}
		]
	},
	{
		"id": "dungeon_kitchen",
		"title": "던전 식당 위생 점검",
		"client": "지하 상가 조합",
		"location": "던전 푸드코트 G-7",
		"summary": "불법 식재료와 기름때를 정리해 인간 탐사대 신고를 피합니다.",
		"primary_stat": "pollution",
		"difficulty": 2,
		"reward": {
			"money": 45,
			"hell_trust": 4,
			"human_reputation": 2,
			"hygiene": 9,
			"illegal_risk": -1
		},
		"tasks": [
			{
				"id": "GreasePool",
				"label": "기름 웅덩이",
				"action": "흡착 모래와 세제로 바닥을 닦았습니다.",
				"kind": "slime",
				"position": Vector2(355, 330),
				"size": Vector2(140, 78)
			},
			{
				"id": "BadCrates",
				"label": "수상한 식재료",
				"action": "원산지 표기가 없는 상자를 폐기했습니다.",
				"kind": "rubble",
				"position": Vector2(650, 405),
				"size": Vector2(142, 86)
			},
			{
				"id": "SmokeVent",
				"label": "막힌 환풍구",
				"action": "환풍구의 그을음과 점액을 긁어냈습니다.",
				"kind": "trap",
				"position": Vector2(920, 290),
				"size": Vector2(128, 76)
			}
		]
	}
]

var day: int = INITIAL_DAY
var money: int = INITIAL_MONEY
var hell_trust: int = INITIAL_HELL_TRUST
var human_reputation: int = INITIAL_HUMAN_REPUTATION
var hygiene: int = INITIAL_HYGIENE
var illegal_risk: int = INITIAL_ILLEGAL_RISK
var staff_roster: Array[Dictionary] = []
var gear_inventory: Array[Dictionary] = []
var selected_staff_ids: Array[String] = []
var selected_gear_ids: Array[String] = []
var last_report: String = ""
var last_settlement_report: Dictionary = {}
var selected_contract_id: String = ""
var field_completed_task_ids: Array[String] = []
var field_battle_resolved: bool = false
var field_player_position: Vector2 = Vector2.ZERO
var has_field_player_position: bool = false
var last_battle_report: String = ""


func _ready() -> void:
	reset_assignment_data()


func reset() -> void:
	day = INITIAL_DAY
	money = INITIAL_MONEY
	hell_trust = INITIAL_HELL_TRUST
	human_reputation = INITIAL_HUMAN_REPUTATION
	hygiene = INITIAL_HYGIENE
	illegal_risk = INITIAL_ILLEGAL_RISK
	last_report = ""
	last_settlement_report.clear()
	reset_assignment_data()
	selected_contract_id = ""
	clear_field_operation_state()
	changed.emit()


func get_hud_text() -> String:
	return "Day %d | 자금 %d | 마왕성 신뢰 %d | 인간 평판 %d | 위생 %d | 불법 리스크 %d" % [
		day,
		money,
		hell_trust,
		human_reputation,
		hygiene,
		illegal_risk,
	]


func get_company_status_text() -> String:
	return "자금 %d / 마왕성 신뢰 %d / 인간 평판 %d / 위생 %d / 불법 리스크 %d" % [
		money,
		hell_trust,
		human_reputation,
		hygiene,
		illegal_risk,
	]


func reset_assignment_data() -> void:
	staff_roster = GameDataSource.get_staff()
	gear_inventory = GameDataSource.get_gear()
	selected_staff_ids.clear()
	selected_gear_ids.clear()


func ensure_assignment_data() -> void:
	if staff_roster.is_empty():
		staff_roster = GameDataSource.get_staff()
	if gear_inventory.is_empty():
		gear_inventory = GameDataSource.get_gear()


func get_staff_roster() -> Array[Dictionary]:
	ensure_assignment_data()
	return staff_roster.duplicate(true)


func get_gear_inventory() -> Array[Dictionary]:
	ensure_assignment_data()
	return gear_inventory.duplicate(true)


func get_staff_by_id(staff_id: String) -> Dictionary:
	ensure_assignment_data()
	for member: Dictionary in staff_roster:
		if String(member.get("id", "")) == staff_id:
			return member.duplicate(true)
	return {}


func get_gear_by_id(gear_id: String) -> Dictionary:
	ensure_assignment_data()
	for item: Dictionary in gear_inventory:
		if String(item.get("id", "")) == gear_id:
			return item.duplicate(true)
	return {}


func get_selected_staff_ids() -> Array[String]:
	return selected_staff_ids.duplicate()


func get_selected_gear_ids() -> Array[String]:
	return selected_gear_ids.duplicate()


func is_staff_selected(staff_id: String) -> bool:
	return selected_staff_ids.has(staff_id)


func is_gear_selected(gear_id: String) -> bool:
	return selected_gear_ids.has(gear_id)


func is_staff_injured(staff_id: String) -> bool:
	var member := get_staff_by_id(staff_id)
	return bool(member.get("injured", false))


func toggle_staff_selection(staff_id: String) -> bool:
	ensure_assignment_data()
	if selected_staff_ids.has(staff_id):
		selected_staff_ids.erase(staff_id)
		changed.emit()
		return true

	if selected_staff_ids.size() >= STAFF_SELECTION_LIMIT:
		return false
	if is_staff_injured(staff_id):
		return false
	if get_staff_by_id(staff_id).is_empty():
		return false

	selected_staff_ids.append(staff_id)
	changed.emit()
	return true


func toggle_gear_selection(gear_id: String) -> bool:
	ensure_assignment_data()
	if selected_gear_ids.has(gear_id):
		selected_gear_ids.erase(gear_id)
		changed.emit()
		return true

	if selected_gear_ids.size() >= GEAR_SELECTION_LIMIT:
		return false
	if get_gear_by_id(gear_id).is_empty():
		return false

	selected_gear_ids.append(gear_id)
	changed.emit()
	return true


func clear_assignment_selection() -> void:
	selected_staff_ids.clear()
	selected_gear_ids.clear()


func get_selected_staff_names_text() -> String:
	var names: Array[String] = []
	for staff_id: String in selected_staff_ids:
		var member := get_staff_by_id(staff_id)
		if not member.is_empty():
			names.append(String(member.get("name", staff_id)))
	return "없음" if names.is_empty() else ", ".join(names)


func get_selected_gear_names_text() -> String:
	var names: Array[String] = []
	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		if not item.is_empty():
			names.append(String(item.get("name", gear_id)))
	return "없음" if names.is_empty() else ", ".join(names)


func get_selected_gear_cost() -> int:
	var total := 0
	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		total += int(item.get("cost", 0))
	return total


func get_dispatch_blocker() -> String:
	if not has_selected_contract():
		return "출동할 의뢰를 먼저 선택하세요."
	if selected_staff_ids.size() < STAFF_SELECTION_LIMIT:
		return "출동 직원 %d명을 편성하세요. 현재 %d/%d" % [
			STAFF_SELECTION_LIMIT,
			selected_staff_ids.size(),
			STAFF_SELECTION_LIMIT
		]

	var gear_cost := get_selected_gear_cost()
	if gear_cost > money:
		return "장비 비용이 부족합니다. 현재 자금 %d / 필요 자금 %d" % [money, gear_cost]
	return ""


func is_assignment_ready() -> bool:
	return get_dispatch_blocker().is_empty()


func apply_field_report(
	report: String,
	money_delta: int,
	hell_trust_delta: int,
	human_reputation_delta: int,
	hygiene_delta: int,
	illegal_risk_delta: int
) -> void:
	money += money_delta
	hell_trust += hell_trust_delta
	human_reputation += human_reputation_delta
	hygiene += hygiene_delta
	illegal_risk += illegal_risk_delta
	last_report = report
	changed.emit()


func get_field_contracts() -> Array[Dictionary]:
	return FIELD_CONTRACTS.duplicate(true)


func get_default_contract() -> Dictionary:
	if FIELD_CONTRACTS.is_empty():
		return {}
	return FIELD_CONTRACTS[0].duplicate(true)


func get_contract_by_id(contract_id: String) -> Dictionary:
	for contract: Dictionary in FIELD_CONTRACTS:
		if String(contract.get("id", "")) == contract_id:
			return contract.duplicate(true)
	return {}


func select_contract(contract_id: String) -> bool:
	var contract := get_contract_by_id(contract_id)
	if contract.is_empty():
		return false

	selected_contract_id = contract_id
	clear_field_operation_state()
	changed.emit()
	return true


func clear_selected_contract() -> void:
	selected_contract_id = ""
	clear_field_operation_state()
	changed.emit()


func has_selected_contract() -> bool:
	return not selected_contract_id.is_empty() and not get_selected_contract().is_empty()


func get_selected_contract() -> Dictionary:
	if selected_contract_id.is_empty():
		return {}
	return get_contract_by_id(selected_contract_id)


func get_reward_text(contract: Dictionary) -> String:
	var reward: Dictionary = contract.get("reward", {})
	return format_reward_text(reward)


func format_reward_text(reward: Dictionary) -> String:
	return "자금 %s / 신뢰 %s / 평판 %s / 위생 %s / 리스크 %s" % [
		format_delta(int(reward.get("money", 0))),
		format_delta(int(reward.get("hell_trust", 0))),
		format_delta(int(reward.get("human_reputation", 0))),
		format_delta(int(reward.get("hygiene", 0))),
		format_delta(int(reward.get("illegal_risk", 0)))
	]


func get_combat_event(contract: Dictionary) -> Dictionary:
	var combat_event: Dictionary = contract.get("combat_event", {})
	return combat_event.duplicate(true)


func contract_has_combat_event(contract: Dictionary) -> bool:
	return not get_combat_event(contract).is_empty()


func should_spawn_combat_event(contract: Dictionary) -> bool:
	return contract_has_combat_event(contract) and not field_battle_resolved


func get_settlement_reward(contract: Dictionary) -> Dictionary:
	var reward: Dictionary = contract.get("reward", {}).duplicate(true)
	add_reward_delta(reward, get_assignment_reward_adjustment(contract))
	if not field_battle_resolved:
		return reward

	var combat_event := get_combat_event(contract)
	var bonus: Dictionary = combat_event.get("settlement_bonus", {})
	for key: String in ["money", "hell_trust", "human_reputation", "hygiene", "illegal_risk"]:
		reward[key] = int(reward.get(key, 0)) + int(bonus.get(key, 0))
	return reward


func get_assignment_reward_adjustment(contract: Dictionary) -> Dictionary:
	var adjustment := create_empty_reward()

	adjustment["money"] = int(adjustment["money"]) - get_selected_gear_cost()

	if selected_staff_ids.size() >= STAFF_SELECTION_LIMIT:
		var primary_stat := get_contract_primary_stat(contract)
		var team_score := calculate_assignment_score(primary_stat)
		var required_score := get_contract_required_score(contract)
		if team_score >= required_score:
			adjustment["hell_trust"] = int(adjustment["hell_trust"]) + 2
			adjustment["hygiene"] = int(adjustment["hygiene"]) + 2
		else:
			adjustment["hell_trust"] = int(adjustment["hell_trust"]) - 2
			adjustment["hygiene"] = int(adjustment["hygiene"]) - 3
			adjustment["illegal_risk"] = int(adjustment["illegal_risk"]) + 2

	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		var effect := String(item.get("effect", ""))
		var power := int(item.get("power", 0))
		match effect:
			"pollution":
				adjustment["hygiene"] = int(adjustment["hygiene"]) + power
			"hauling":
				adjustment["money"] = int(adjustment["money"]) + power * 3
				adjustment["human_reputation"] = int(adjustment["human_reputation"]) + 1
			"trap":
				adjustment["hell_trust"] = int(adjustment["hell_trust"]) + power
				adjustment["illegal_risk"] = int(adjustment["illegal_risk"]) - 1
			"human_profit":
				adjustment["money"] = int(adjustment["money"]) + power
				adjustment["human_reputation"] = int(adjustment["human_reputation"]) + 2
			"illegal_profit":
				adjustment["money"] = int(adjustment["money"]) + power
				adjustment["illegal_risk"] = int(adjustment["illegal_risk"]) + 5

	return adjustment


func create_empty_reward() -> Dictionary:
	return {
		"money": 0,
		"hell_trust": 0,
		"human_reputation": 0,
		"hygiene": 0,
		"illegal_risk": 0
	}


func add_reward_delta(reward: Dictionary, delta: Dictionary) -> void:
	for key: String in ["money", "hell_trust", "human_reputation", "hygiene", "illegal_risk"]:
		reward[key] = int(reward.get(key, 0)) + int(delta.get(key, 0))


func get_contract_primary_stat(contract: Dictionary) -> String:
	return String(contract.get("primary_stat", "cleanup"))


func get_contract_required_score(contract: Dictionary) -> int:
	return max(2, int(contract.get("difficulty", 2)) * 2)


func calculate_assignment_score(primary_stat: String) -> int:
	var score := 0
	for staff_id: String in selected_staff_ids:
		var member := get_staff_by_id(staff_id)
		score += int(member.get(primary_stat, 0))
	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		if String(item.get("effect", "")) == primary_stat:
			score += int(item.get("power", 0))
	return score


func get_stat_name(stat_id: String) -> String:
	match stat_id:
		"cleanup":
			return "청소"
		"pollution":
			return "오염 제거"
		"hauling":
			return "운반"
		"trap":
			return "함정"
		_:
			return stat_id


func get_gear_effect_text(item: Dictionary) -> String:
	var effect := String(item.get("effect", ""))
	var power := int(item.get("power", 0))
	match effect:
		"pollution":
			return "위생 +%d" % power
		"hauling":
			return "자금 +%d, 인간 평판 +1" % (power * 3)
		"trap":
			return "마왕성 신뢰 +%d, 불법 리스크 -1" % power
		"human_profit":
			return "자금 +%d, 인간 평판 +2" % power
		"illegal_profit":
			return "자금 +%d, 불법 리스크 +5" % power
		_:
			return "%s +%d" % [get_stat_name(effect), power]


func get_assignment_effect_lines(contract: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("직원: %s" % get_selected_staff_names_text())
	lines.append("장비: %s" % get_selected_gear_names_text())

	var gear_cost := get_selected_gear_cost()
	if gear_cost > 0:
		lines.append("장비 비용: 자금 -%d" % gear_cost)

	if selected_staff_ids.size() >= STAFF_SELECTION_LIMIT:
		var primary_stat := get_contract_primary_stat(contract)
		var score := calculate_assignment_score(primary_stat)
		var required := get_contract_required_score(contract)
		var result := "충분" if score >= required else "부족"
		lines.append("팀 숙련도(%s): %d/%d %s" % [get_stat_name(primary_stat), score, required, result])

	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		if not item.is_empty():
			lines.append("%s: %s" % [String(item.get("name", gear_id)), get_gear_effect_text(item)])

	return lines


func get_field_task_effect_lines(task: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var task_stat := get_task_primary_stat(task)
	var staff_line := get_best_staff_task_effect_line(task_stat)
	if not staff_line.is_empty():
		lines.append(staff_line)

	for gear_id: String in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		if item.is_empty() or not is_gear_relevant_to_task(item, task, task_stat):
			continue
		lines.append("%s: %s" % [
			String(item.get("name", gear_id)),
			get_gear_task_effect_text(item, task, task_stat)
		])

	return lines


func get_task_primary_stat(task: Dictionary) -> String:
	if task.has("primary_stat"):
		return String(task.get("primary_stat", "cleanup"))

	match String(task.get("kind", "")):
		"slime":
			return "pollution"
		"trap":
			return "trap"
		"bone", "rubble":
			return "hauling"
		_:
			return "cleanup"


func get_best_staff_task_effect_line(task_stat: String) -> String:
	var best_member: Dictionary = {}
	var best_score := -1

	for staff_id: String in selected_staff_ids:
		var member := get_staff_by_id(staff_id)
		if member.is_empty():
			continue

		var score := int(member.get(task_stat, 0))
		if score > best_score:
			best_member = member
			best_score = score

	if best_member.is_empty() or best_score <= 0:
		return ""

	return "%s: %s +%d" % [
		String(best_member.get("name", "직원")),
		get_stat_name(task_stat),
		best_score
	]


func is_gear_relevant_to_task(item: Dictionary, task: Dictionary, task_stat: String) -> bool:
	var effect := String(item.get("effect", ""))
	if effect == task_stat:
		return true

	var task_kind := String(task.get("kind", ""))
	if task_kind == "bone" and effect == "human_profit":
		return true
	if (task_kind == "bone" or task_kind == "rubble") and effect == "illegal_profit":
		return true
	return false


func get_gear_task_effect_text(item: Dictionary, task: Dictionary, task_stat: String) -> String:
	var effect := String(item.get("effect", ""))
	if effect == task_stat:
		return get_gear_effect_text(item)

	match effect:
		"human_profit":
			return "유품 가치 확인"
		"illegal_profit":
			return "거래 기록 확보"
		_:
			return get_gear_effect_text(item)


func mark_field_task_completed(task_id: String) -> void:
	if field_completed_task_ids.has(task_id):
		return

	field_completed_task_ids.append(task_id)
	changed.emit()


func is_field_task_completed(task_id: String) -> bool:
	return field_completed_task_ids.has(task_id)


func set_field_battle_resolved(report: String) -> void:
	field_battle_resolved = true
	last_battle_report = report
	changed.emit()


func set_field_player_position(position: Vector2) -> void:
	field_player_position = position
	has_field_player_position = true
	changed.emit()


func get_field_player_position(default_position: Vector2) -> Vector2:
	if has_field_player_position:
		return field_player_position
	return default_position


func clear_field_operation_state() -> void:
	field_completed_task_ids.clear()
	field_battle_resolved = false
	field_player_position = Vector2.ZERO
	has_field_player_position = false
	last_battle_report = ""


func apply_contract_field_report(contract: Dictionary, completed_count: int, total_count: int) -> void:
	var reward := get_settlement_reward(contract)
	var before_values := get_company_values()
	var battle_resolved := field_battle_resolved
	var battle_report := last_battle_report
	var assignment_lines := get_assignment_effect_lines(contract)
	var staff_changes := apply_selected_staff_stamina_cost(completed_count, total_count, battle_resolved)
	var battle_result_text := ""
	if battle_resolved:
		battle_result_text = " | 전투 해결"

	var report: String = "%s 보고: 작업 %d/%d 완료%s | %s" % [
		String(contract.get("title", "현장")),
		completed_count,
		total_count,
		battle_result_text,
		format_reward_text(reward)
	]

	selected_contract_id = ""
	clear_field_operation_state()
	clear_assignment_selection()
	var money_delta := int(reward.get("money", 0))
	var hell_trust_delta := int(reward.get("hell_trust", 0))
	var human_reputation_delta := int(reward.get("human_reputation", 0))
	var hygiene_delta := int(reward.get("hygiene", 0))
	var illegal_risk_delta := int(reward.get("illegal_risk", 0))

	money += money_delta
	hell_trust += hell_trust_delta
	human_reputation += human_reputation_delta
	hygiene += hygiene_delta
	illegal_risk += illegal_risk_delta
	last_report = report
	last_settlement_report = {
		"contract_title": String(contract.get("title", "현장")),
		"client": String(contract.get("client", "")),
		"location": String(contract.get("location", "")),
		"completed_count": completed_count,
		"total_count": total_count,
		"battle_resolved": battle_resolved,
		"battle_report": battle_report,
		"assignment_lines": assignment_lines,
		"staff_changes": staff_changes,
		"reward": reward.duplicate(true),
		"before": before_values,
		"after": get_company_values()
	}
	changed.emit()


func apply_selected_staff_stamina_cost(completed_count: int, total_count: int, battle_resolved: bool) -> Array[String]:
	var lines: Array[String] = []
	if selected_staff_ids.is_empty():
		return lines

	var stamina_cost := 8 + completed_count * 4
	if completed_count < total_count:
		stamina_cost += (total_count - completed_count) * 2
	if battle_resolved:
		stamina_cost += 8

	for staff_id: String in selected_staff_ids:
		var index := get_staff_index_by_id(staff_id)
		if index == -1:
			continue

		var before_stamina := int(staff_roster[index].get("stamina", 0))
		var after_stamina: int = max(0, before_stamina - stamina_cost)
		staff_roster[index]["stamina"] = after_stamina
		if after_stamina <= 0:
			staff_roster[index]["injured"] = true

		lines.append("%s: 체력 %d -> %d%s" % [
			String(staff_roster[index].get("name", staff_id)),
			before_stamina,
			after_stamina,
			" / 부상" if bool(staff_roster[index].get("injured", false)) else ""
		])

	return lines


func get_staff_index_by_id(staff_id: String) -> int:
	ensure_assignment_data()
	for index in range(staff_roster.size()):
		if String(staff_roster[index].get("id", "")) == staff_id:
			return index
	return -1


func set_last_report(report: String) -> void:
	last_report = report
	changed.emit()


func has_last_settlement_report() -> bool:
	return not last_settlement_report.is_empty()


func get_last_settlement_report() -> Dictionary:
	return last_settlement_report.duplicate(true)


func clear_last_settlement_report() -> void:
	last_settlement_report.clear()
	changed.emit()


func advance_day_after_report() -> void:
	if not has_last_settlement_report():
		return

	day += 1
	last_settlement_report.clear()
	last_report = "Day %d 업무 시작: 의뢰 게시판에서 다음 현장을 고르세요." % day
	changed.emit()


func get_company_values() -> Dictionary:
	return {
		"money": money,
		"hell_trust": hell_trust,
		"human_reputation": human_reputation,
		"hygiene": hygiene,
		"illegal_risk": illegal_risk
	}


func format_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)
