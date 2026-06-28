extends Node

signal changed

const INITIAL_DAY: int = 1
const INITIAL_MONEY: int = 300
const INITIAL_HELL_TRUST: int = 50
const INITIAL_HUMAN_REPUTATION: int = 10
const INITIAL_HYGIENE: int = 70
const INITIAL_ILLEGAL_RISK: int = 0

const FIELD_CONTRACTS: Array[Dictionary] = [
	{
		"id": "sewer_recovery",
		"title": "버려진 하수 던전",
		"client": "마왕성 시설관리과",
		"location": "하수 처리 던전 B-12",
		"summary": "용사 파티가 지나간 뒤 오염된 하수 던전을 복구합니다.",
		"reward": {
			"money": 55,
			"hell_trust": 6,
			"human_reputation": 1,
			"hygiene": 5,
			"illegal_risk": 1
		},
		"tasks": [
			{
				"id": "SlimePuddle",
				"label": "끈적 점액",
				"action": "소독 점액통으로 바닥을 닦았습니다.",
				"kind": "slime",
				"position": Vector2(330, 335),
				"size": Vector2(140, 82)
			},
			{
				"id": "BrokenTrap",
				"label": "망가진 함정",
				"action": "스프링과 발판을 다시 맞췄습니다.",
				"kind": "trap",
				"position": Vector2(655, 318),
				"size": Vector2(132, 72)
			},
			{
				"id": "BonePile",
				"label": "뼈무더기",
				"action": "사체 포대에 담아 수거했습니다.",
				"kind": "bone",
				"position": Vector2(905, 452),
				"size": Vector2(126, 80)
			}
		],
		"combat_event": {
			"id": "sewer_holdout",
			"title": "하수 던전 잔당 진압",
			"label": "소란스러운 잔당",
			"action": "청소 작업을 방해하는 탐사대 잔당과 교전합니다.",
			"position": Vector2(760, 465),
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
var last_report: String = ""
var selected_contract_id: String = ""
var field_completed_task_ids: Array[String] = []
var field_battle_resolved: bool = false
var last_battle_report: String = ""


func reset() -> void:
	day = INITIAL_DAY
	money = INITIAL_MONEY
	hell_trust = INITIAL_HELL_TRUST
	human_reputation = INITIAL_HUMAN_REPUTATION
	hygiene = INITIAL_HYGIENE
	illegal_risk = INITIAL_ILLEGAL_RISK
	last_report = ""
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
	if not field_battle_resolved:
		return reward

	var combat_event := get_combat_event(contract)
	var bonus: Dictionary = combat_event.get("settlement_bonus", {})
	for key: String in ["money", "hell_trust", "human_reputation", "hygiene", "illegal_risk"]:
		reward[key] = int(reward.get(key, 0)) + int(bonus.get(key, 0))
	return reward


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


func clear_field_operation_state() -> void:
	field_completed_task_ids.clear()
	field_battle_resolved = false
	last_battle_report = ""


func apply_contract_field_report(contract: Dictionary, completed_count: int, total_count: int) -> void:
	var reward := get_settlement_reward(contract)
	var battle_result_text := ""
	if field_battle_resolved:
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
	apply_field_report(
		report,
		int(reward.get("money", 0)),
		int(reward.get("hell_trust", 0)),
		int(reward.get("human_reputation", 0)),
		int(reward.get("hygiene", 0)),
		int(reward.get("illegal_risk", 0))
	)


func set_last_report(report: String) -> void:
	last_report = report
	changed.emit()


func format_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)
