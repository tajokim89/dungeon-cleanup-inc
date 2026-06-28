extends RefCounted
class_name GameData


static func get_staff() -> Array[Dictionary]:
	return [
		{
			"id": "grik",
			"name": "그릭",
			"species": "고블린",
			"role": "잡동사니 회수",
			"cleanup": 3,
			"pollution": 1,
			"hauling": 1,
			"trap": 1,
			"stamina": 100,
			"injured": false,
		},
		{
			"id": "melta",
			"name": "멜타",
			"species": "슬라임",
			"role": "오염 제거",
			"cleanup": 2,
			"pollution": 4,
			"hauling": 1,
			"trap": 1,
			"stamina": 100,
			"injured": false,
		},
		{
			"id": "volg",
			"name": "볼그",
			"species": "오크",
			"role": "시체/잔해 운반",
			"cleanup": 2,
			"pollution": 1,
			"hauling": 4,
			"trap": 1,
			"stamina": 100,
			"injured": false,
		},
		{
			"id": "pipit",
			"name": "피핏",
			"species": "임프",
			"role": "함정 복구/장부 조작",
			"cleanup": 1,
			"pollution": 1,
			"hauling": 1,
			"trap": 4,
			"stamina": 100,
			"injured": false,
		},
	]


static func get_gear() -> Array[Dictionary]:
	return [
		{"id": "disinfect_slime", "name": "소독 점액통", "cost": 20, "effect": "pollution", "power": 2},
		{"id": "corpse_bag", "name": "사체 운반 포대", "cost": 15, "effect": "hauling", "power": 2},
		{"id": "trap_kit", "name": "함정 수리 키트", "cost": 25, "effect": "trap", "power": 2},
		{"id": "relic_lens", "name": "유품 감정 렌즈", "cost": 20, "effect": "human_profit", "power": 15},
		{"id": "black_ledger", "name": "검은 장부", "cost": 0, "effect": "illegal_profit", "power": 30},
	]


static func get_contract_pool() -> Array[Dictionary]:
	return [
		{
			"id": "goblin_barracks_cleanup",
			"title": "고블린 막사 사후 정리",
			"client": "지하 2층 막사 관리실",
			"pay": 75,
			"difficulty": 2,
			"primary_stat": "cleanup",
			"description": "용사 파티가 지나간 뒤 침상, 식기, 부서진 방패를 정리해야 한다.",
			"options": ["proper_restore", "cheap_cleanup", "black_market"],
		},
		{
			"id": "holy_water_sanitation",
			"title": "성수 오염 구역 소독",
			"client": "흡혈귀 거주구",
			"pay": 90,
			"difficulty": 3,
			"primary_stat": "pollution",
			"description": "성기사의 성수 폭탄이 터진 복도를 소독해야 한다.",
			"options": ["proper_restore", "cheap_cleanup", "corpse_return"],
		},
		{
			"id": "treasure_room_repair",
			"title": "보물방 약탈 피해 복구",
			"client": "미믹 조합",
			"pay": 110,
			"difficulty": 3,
			"primary_stat": "trap",
			"description": "보물상자 위장 장치와 경보 함정을 복구해야 한다.",
			"options": ["proper_restore", "cheap_cleanup", "black_market"],
		},
		{
			"id": "mimic_corpse_recovery",
			"title": "미믹 사체 회수",
			"client": "던전 생태관리과",
			"pay": 100,
			"difficulty": 3,
			"primary_stat": "hauling",
			"description": "반쯤 열린 미믹 사체와 안에 남은 인간 장비를 수습해야 한다.",
			"options": ["proper_restore", "corpse_return", "black_market"],
			"requires_tactical_event": true,
		},
		{
			"id": "human_body_return",
			"title": "인간 모험가 시체 반환",
			"client": "던전 외곽 연락소",
			"pay": 60,
			"difficulty": 2,
			"primary_stat": "hauling",
			"description": "인간 길드에서 시체 반환 요청이 들어왔다. 유료 인도 가능.",
			"options": ["corpse_return", "black_market", "cheap_cleanup"],
		},
		{
			"id": "sealed_route_repair",
			"title": "침입로 봉쇄 및 함정 복구",
			"client": "마왕성 보안감사실",
			"pay": 120,
			"difficulty": 4,
			"primary_stat": "trap",
			"description": "도적 파티가 뚫어놓은 비밀 통로를 막고 함정을 다시 설치해야 한다.",
			"options": ["proper_restore", "cheap_cleanup"],
		},
	]


static func get_resolution_options() -> Dictionary:
	return {
		"proper_restore": {
			"name": "정식 복구",
			"desc": "규정대로 처리한다. 수익은 낮지만 신뢰와 위생이 좋아진다.",
			"money_bonus": 0,
			"hell_trust": 6,
			"human_reputation": 0,
			"hygiene": 8,
			"illegal_risk": 0,
			"stamina_cost": 18,
		},
		"cheap_cleanup": {
			"name": "저가 처리",
			"desc": "보이는 곳만 치운다. 비용은 줄지만 위생과 신뢰가 떨어질 수 있다.",
			"money_bonus": 25,
			"hell_trust": -4,
			"human_reputation": 0,
			"hygiene": -8,
			"illegal_risk": 5,
			"stamina_cost": 10,
		},
		"corpse_return": {
			"name": "시체 유료 인도",
			"desc": "인간 길드에 시체/유품을 유료 반환한다.",
			"money_bonus": 45,
			"hell_trust": -2,
			"human_reputation": 8,
			"hygiene": 2,
			"illegal_risk": 8,
			"stamina_cost": 16,
		},
		"black_market": {
			"name": "암시장 판매",
			"desc": "주운 인간 장비와 유품을 몰래 판다. 돈은 좋지만 위험하다.",
			"money_bonus": 70,
			"hell_trust": -6,
			"human_reputation": -5,
			"hygiene": -3,
			"illegal_risk": 20,
			"stamina_cost": 14,
		},
	}
