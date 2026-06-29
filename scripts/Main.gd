extends Control

const UiAssetStyles = preload("res://scripts/UiAssetStyles.gd")
const GameDataSource = preload("res://data/GameData.gd")
const TacticalEventScene = preload("res://scenes/TacticalEvent.tscn")

const PHASE_CONTRACT_SELECT: String = "contract_select"
const PHASE_STAFF_SELECT: String = "staff_select"
const PHASE_RESOLUTION_SELECT: String = "resolution_select"
const PHASE_TACTICAL_EVENT: String = "tactical_event"
const PHASE_RESULT: String = "result"
const PHASE_GAME_OVER: String = "game_over"

const COLOR_BACKGROUND: Color = Color(0.063, 0.063, 0.078)
const COLOR_PANEL: Color = Color(0.106, 0.106, 0.141)
const COLOR_PANEL_ALT: Color = Color(0.141, 0.141, 0.196)
const COLOR_BORDER: Color = Color(0.357, 0.29, 0.2)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_GREEN: Color = Color(0.525, 0.722, 0.42)
const COLOR_PURPLE: Color = Color(0.553, 0.42, 0.722)
const COLOR_DANGER: Color = Color(0.78, 0.361, 0.361)
const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)

var day: int = 1
var max_day: int = 5
var money: int = 300
var hell_trust: int = 50
var human_reputation: int = 10
var hygiene: int = 70
var illegal_risk: int = 0

var phase: String = PHASE_CONTRACT_SELECT
var staff: Array[Dictionary] = []
var gear: Array[Dictionary] = []
var contract_pool: Array[Dictionary] = []
var resolution_options: Dictionary = {}
var today_contracts: Array[Dictionary] = []

var selected_contract: Dictionary = {}
var selected_staff_ids: Array[String] = []
var selected_gear_ids: Array[String] = []
var selected_resolution_id: String = ""
var selected_gear_cost: int = 0

var result_lines: Array[String] = []
var team_error: String = ""
var failure_reason: String = ""
var final_grade: String = ""
var tactical_played: bool = false
var tactical_success: bool = false


func _ready() -> void:
	restart_game()


func restart_game() -> void:
	day = 1
	money = 300
	hell_trust = 50
	human_reputation = 10
	hygiene = 70
	illegal_risk = 0
	phase = PHASE_CONTRACT_SELECT
	staff = GameDataSource.get_staff()
	gear = GameDataSource.get_gear()
	contract_pool = GameDataSource.get_contract_pool()
	resolution_options = GameDataSource.get_resolution_options()
	selected_contract = {}
	selected_staff_ids.clear()
	selected_gear_ids.clear()
	selected_resolution_id = ""
	selected_gear_cost = 0
	result_lines.clear()
	team_error = ""
	failure_reason = ""
	final_grade = ""
	tactical_played = false
	tactical_success = false
	generate_today_contracts()
	refresh_ui()


func generate_today_contracts() -> void:
	today_contracts.clear()
	for i in range(3):
		var idx: int = ((day - 1) * 3 + i) % contract_pool.size()
		today_contracts.append(contract_pool[idx].duplicate(true))


func refresh_ui() -> void:
	clear_ui()

	var background := ColorRect.new()
	background.name = "Background"
	background.color = COLOR_BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.name = "P0Layout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 32
	layout.offset_top = 24
	layout.offset_right = -32
	layout.offset_bottom = -24
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	draw_hud(layout)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	match phase:
		PHASE_CONTRACT_SELECT:
			draw_contract_select(content)
		PHASE_STAFF_SELECT:
			draw_staff_select(content)
		PHASE_RESOLUTION_SELECT:
			draw_resolution_select(content)
		PHASE_TACTICAL_EVENT:
			draw_tactical_placeholder(content)
		PHASE_RESULT:
			draw_result(content)
		PHASE_GAME_OVER:
			draw_game_over(content)


func clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func draw_hud(parent: Node) -> void:
	var hud_box := make_panel_container(COLOR_PANEL_ALT, COLOR_BORDER, 3)
	parent.add_child(hud_box)

	var hud_margin := MarginContainer.new()
	hud_margin.add_theme_constant_override("margin_left", 16)
	hud_margin.add_theme_constant_override("margin_top", 12)
	hud_margin.add_theme_constant_override("margin_right", 16)
	hud_margin.add_theme_constant_override("margin_bottom", 12)
	hud_box.add_child(hud_margin)

	var hud_layout := VBoxContainer.new()
	hud_layout.add_theme_constant_override("separation", 6)
	hud_margin.add_child(hud_layout)

	var title := make_label("던전 클린업 주식회사", 28, COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_layout.add_child(title)

	var hud_text: String = "Day %d/%d | 자금 %d | 마왕성 신뢰 %d | 인간 평판 %d | 위생 %d | 불법 리스크 %d" % [
		day,
		max_day,
		money,
		hell_trust,
		human_reputation,
		hygiene,
		illegal_risk,
	]
	var hud := make_label(hud_text, 17, COLOR_TEXT)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_layout.add_child(hud)


func draw_contract_select(parent: Node) -> void:
	parent.add_child(make_label("오늘의 사고 접수", 24, COLOR_GOLD))
	parent.add_child(make_label("하루에 의뢰 1개를 처리합니다. 보수, 위험, 필요한 능력치를 보고 고르세요.", 15, COLOR_MUTED))

	for contract in today_contracts:
		var border_color: Color = COLOR_DANGER if bool(contract.get("requires_tactical_event", false)) else COLOR_BORDER
		var card := make_card(parent, border_color)
		card.add_child(make_label(str(contract["title"]), 20, COLOR_GOLD))
		card.add_child(make_label("의뢰인: %s" % str(contract["client"]), 15, COLOR_MUTED))
		card.add_child(make_label(
			"보수 %d | 난이도 %d | 주요 능력 %s" % [
				int(contract["pay"]),
				int(contract["difficulty"]),
				get_stat_name(str(contract["primary_stat"])),
			],
			15,
			COLOR_TEXT
		))
		card.add_child(make_label(str(contract["description"]), 15))
		if bool(contract.get("requires_tactical_event", false)):
			card.add_child(make_label("위험 의뢰: 처리 전에 짧은 전술 이벤트가 발생합니다.", 15, COLOR_DANGER))

		var button := make_button("이 의뢰 선택")
		button.pressed.connect(_on_contract_selected.bind(contract))
		card.add_child(button)


func draw_staff_select(parent: Node) -> void:
	parent.add_child(make_label("직원/장비 배치", 24, COLOR_GOLD))
	parent.add_child(make_label(get_contract_summary(selected_contract), 15, COLOR_TEXT))
	parent.add_child(make_label("직원은 정확히 2명, 장비는 최대 2개까지 선택합니다.", 15, COLOR_MUTED))

	if team_error != "":
		parent.add_child(make_label(team_error, 15, COLOR_DANGER))

	parent.add_child(make_label("직원 선택 %d/2" % selected_staff_ids.size(), 18, COLOR_GOLD))
	var staff_grid := GridContainer.new()
	staff_grid.columns = 2
	staff_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(staff_grid)

	for member in staff:
		var staff_id := str(member["id"])
		var selected := selected_staff_ids.has(staff_id)
		var injured := bool(member["injured"])
		var button := make_button("%s%s (%s)\n역할: %s | 체력 %d%s\n청소 %d / 오염 %d / 운반 %d / 함정 %d" % [
			"[선택] " if selected else "",
			str(member["name"]),
			str(member["species"]),
			str(member["role"]),
			int(member["stamina"]),
			" | 부상" if injured else "",
			int(member["cleanup"]),
			int(member["pollution"]),
			int(member["hauling"]),
			int(member["trap"]),
		])
		button.toggle_mode = true
		button.button_pressed = selected
		button.disabled = not selected and (injured or selected_staff_ids.size() >= 2)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 86)
		button.pressed.connect(_on_staff_pressed.bind(staff_id))
		staff_grid.add_child(button)

	parent.add_child(make_label("장비 선택 %d/2 | 선택 장비 비용 %d" % [
		selected_gear_ids.size(),
		get_selected_gear_cost(),
	], 18, COLOR_GOLD))

	var gear_grid := GridContainer.new()
	gear_grid.columns = 2
	gear_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(gear_grid)

	for item in gear:
		var gear_id := str(item["id"])
		var selected := selected_gear_ids.has(gear_id)
		var button := make_button("%s%s | 비용 %d\n효과: %s +%d" % [
			"[선택] " if selected else "",
			str(item["name"]),
			int(item["cost"]),
			get_gear_effect_name(str(item["effect"])),
			int(item["power"]),
		])
		button.toggle_mode = true
		button.button_pressed = selected
		button.disabled = not selected and selected_gear_ids.size() >= 2
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 68)
		button.pressed.connect(_on_gear_pressed.bind(gear_id))
		gear_grid.add_child(button)

	var confirm := make_button("팀 확정")
	confirm.disabled = selected_staff_ids.size() != 2
	confirm.pressed.connect(_on_team_confirmed)
	parent.add_child(confirm)


func draw_resolution_select(parent: Node) -> void:
	parent.add_child(make_label("처리 방식 선택", 24, COLOR_GOLD))
	parent.add_child(make_label(get_contract_summary(selected_contract), 15, COLOR_TEXT))
	parent.add_child(make_label("장비 비용 %d이 이미 차감되었습니다." % selected_gear_cost, 15, COLOR_MUTED))
	parent.add_child(make_label("팀 성공도: %d / 필요 %d" % [
		calculate_team_score(str(selected_contract["primary_stat"])),
		int(selected_contract["difficulty"]) * 2,
	], 15, COLOR_TEXT))
	if bool(selected_contract.get("requires_tactical_event", false)):
		parent.add_child(make_label("위험 의뢰: 처리 방식을 고르면 시체 포대 회수 전술 이벤트가 먼저 시작됩니다.", 15, COLOR_DANGER))

	var option_ids: Array = selected_contract.get("options", [])
	for option_id in option_ids:
		if not resolution_options.has(option_id):
			continue
		var option: Dictionary = resolution_options[option_id]
		var card := make_card(parent, get_resolution_border_color(str(option_id)))
		card.add_child(make_label(str(option["name"]), 20, COLOR_GOLD))
		card.add_child(make_label(str(option["desc"]), 15, COLOR_TEXT))
		card.add_child(make_label(get_option_delta_text(option), 15, COLOR_MUTED))
		var button := make_button("이 방식으로 처리")
		button.pressed.connect(_on_resolution_selected.bind(str(option_id)))
		card.add_child(button)


func draw_result(parent: Node) -> void:
	parent.add_child(make_label("정산 결과", 24, COLOR_GOLD))
	for line in result_lines:
		parent.add_child(make_label(line, 15, get_result_line_color(line)))

	var next_button: Button = make_button("최종 평가 보기" if day >= max_day else "다음 날로")
	next_button.pressed.connect(_on_result_confirmed)
	parent.add_child(next_button)


func draw_tactical_placeholder(parent: Node) -> void:
	parent.add_child(make_label("전술 이벤트 준비 중", 24, COLOR_GOLD))
	parent.add_child(make_label("시체 포대 회수 현장으로 이동합니다.", 15, COLOR_MUTED))


func draw_game_over(parent: Node) -> void:
	var heading: String = "운영 실패" if failure_reason != "" else "5일 평가"
	parent.add_child(make_label(heading, 26, COLOR_GOLD))
	if failure_reason != "":
		parent.add_child(make_label(failure_reason, 18, COLOR_DANGER))
	else:
		parent.add_child(make_label(final_grade, 20, COLOR_GREEN if final_grade.begins_with("A") or final_grade.begins_with("B") else COLOR_GOLD))

	parent.add_child(make_label("최종 자원: 자금 %d | 마왕성 신뢰 %d | 인간 평판 %d | 위생 %d | 불법 리스크 %d" % [
		money,
		hell_trust,
		human_reputation,
		hygiene,
		illegal_risk,
	], 15, COLOR_TEXT))

	parent.add_child(make_label("직원 상태", 18, COLOR_GOLD))
	for member in staff:
		parent.add_child(make_label("%s: 체력 %d%s" % [
			str(member["name"]),
			int(member["stamina"]),
			" / 부상" if bool(member["injured"]) else "",
		], 15, COLOR_DANGER if bool(member["injured"]) else COLOR_TEXT))

	var restart := make_button("처음부터 다시")
	restart.pressed.connect(restart_game)
	parent.add_child(restart)


func _on_contract_selected(contract: Dictionary) -> void:
	selected_contract = contract.duplicate(true)
	selected_staff_ids.clear()
	selected_gear_ids.clear()
	selected_resolution_id = ""
	selected_gear_cost = 0
	tactical_played = false
	tactical_success = false
	team_error = ""
	phase = PHASE_STAFF_SELECT
	refresh_ui()


func _on_staff_pressed(staff_id: String) -> void:
	team_error = ""
	if selected_staff_ids.has(staff_id):
		selected_staff_ids.erase(staff_id)
	elif selected_staff_ids.size() < 2 and not is_staff_injured(staff_id):
		selected_staff_ids.append(staff_id)
	refresh_ui()


func _on_gear_pressed(gear_id: String) -> void:
	team_error = ""
	if selected_gear_ids.has(gear_id):
		selected_gear_ids.erase(gear_id)
	elif selected_gear_ids.size() < 2:
		selected_gear_ids.append(gear_id)
	refresh_ui()


func _on_team_confirmed() -> void:
	if selected_staff_ids.size() != 2:
		team_error = "직원 2명을 선택해야 합니다."
		refresh_ui()
		return

	selected_gear_cost = get_selected_gear_cost()
	if selected_gear_cost > money:
		team_error = "장비 비용이 부족합니다. 현재 자금 %d / 필요 자금 %d" % [money, selected_gear_cost]
		refresh_ui()
		return

	money -= selected_gear_cost
	team_error = ""
	phase = PHASE_RESOLUTION_SELECT
	refresh_ui()


func _on_resolution_selected(option_id: String) -> void:
	selected_resolution_id = option_id
	if bool(selected_contract.get("requires_tactical_event", false)):
		start_tactical_event()
		return

	apply_result(option_id)
	if failure_reason != "":
		phase = PHASE_GAME_OVER
	else:
		phase = PHASE_RESULT
	refresh_ui()


func _on_result_confirmed() -> void:
	if day >= max_day:
		final_grade = get_final_grade()
		phase = PHASE_GAME_OVER
	else:
		day += 1
		selected_contract = {}
		selected_staff_ids.clear()
		selected_gear_ids.clear()
		selected_resolution_id = ""
		selected_gear_cost = 0
		tactical_played = false
		tactical_success = false
		result_lines.clear()
		generate_today_contracts()
		phase = PHASE_CONTRACT_SELECT
	refresh_ui()


func start_tactical_event() -> void:
	phase = PHASE_TACTICAL_EVENT
	clear_ui()

	var event: Node = TacticalEventScene.instantiate()
	event.connect("tactical_completed", Callable(self, "_on_tactical_completed"))
	add_child(event)


func _on_tactical_completed(success: bool) -> void:
	tactical_played = true
	tactical_success = success
	apply_result(selected_resolution_id)
	if failure_reason != "":
		phase = PHASE_GAME_OVER
	else:
		phase = PHASE_RESULT
	refresh_ui()


func apply_result(option_id: String) -> void:
	var option: Dictionary = resolution_options[option_id]
	var before_money := money
	var before_hell_trust := hell_trust
	var before_human_reputation := human_reputation
	var before_hygiene := hygiene
	var before_illegal_risk := illegal_risk

	result_lines.clear()
	result_lines.append("%s 처리 완료" % str(selected_contract["title"]))
	if selected_gear_cost > 0:
		result_lines.append("장비 비용: -%d" % selected_gear_cost)

	var contract_pay := int(selected_contract["pay"])
	money += contract_pay
	result_lines.append("의뢰 보수: +%d" % contract_pay)

	money += int(option["money_bonus"])
	hell_trust += int(option["hell_trust"])
	human_reputation += int(option["human_reputation"])
	hygiene += int(option["hygiene"])
	illegal_risk += int(option["illegal_risk"])
	result_lines.append("처리 방식: %s" % str(option["name"]))

	apply_gear_resolution_bonus(option_id)
	apply_team_score_result()
	apply_tactical_result()
	apply_staff_stamina_cost(int(option["stamina_cost"]))

	result_lines.append("자금: %d -> %d (%s)" % [before_money, money, format_delta(money - before_money)])
	result_lines.append("마왕성 신뢰: %d -> %d (%s)" % [before_hell_trust, hell_trust, format_delta(hell_trust - before_hell_trust)])
	result_lines.append("인간 평판: %d -> %d (%s)" % [before_human_reputation, human_reputation, format_delta(human_reputation - before_human_reputation)])
	result_lines.append("위생: %d -> %d (%s)" % [before_hygiene, hygiene, format_delta(hygiene - before_hygiene)])
	result_lines.append("불법 리스크: %d -> %d (%s)" % [before_illegal_risk, illegal_risk, format_delta(illegal_risk - before_illegal_risk)])

	failure_reason = check_failure()


func apply_gear_resolution_bonus(option_id: String) -> void:
	for gear_id in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		var effect := str(item.get("effect", ""))
		var power := int(item.get("power", 0))
		if effect == "human_profit" and option_id == "corpse_return":
			money += power
			human_reputation += 2
			result_lines.append("%s 보너스: 자금 +%d, 인간 평판 +2" % [str(item["name"]), power])
		elif effect == "illegal_profit" and option_id == "black_market":
			money += power
			illegal_risk += 5
			result_lines.append("%s 보너스: 자금 +%d, 불법 리스크 +5" % [str(item["name"]), power])


func apply_team_score_result() -> void:
	var primary_stat := str(selected_contract["primary_stat"])
	var score := calculate_team_score(primary_stat)
	var required := int(selected_contract["difficulty"]) * 2
	if score >= required:
		hell_trust += 2
		hygiene += 2
		result_lines.append("팀 숙련도 충분: %d/%d, 마왕성 신뢰 +2, 위생 +2" % [score, required])
	else:
		hell_trust -= 3
		hygiene -= 5
		illegal_risk += 5
		result_lines.append("팀 숙련도 부족: %d/%d, 마왕성 신뢰 -3, 위생 -5, 불법 리스크 +5" % [score, required])


func apply_tactical_result() -> void:
	if not tactical_played:
		return

	if tactical_success:
		hell_trust += 3
		hygiene += 3
		result_lines.append("전술 이벤트 성공: 마왕성 신뢰 +3, 위생 +3")
	else:
		hell_trust -= 5
		hygiene -= 8
		result_lines.append("전술 이벤트 실패: 마왕성 신뢰 -5, 위생 -8, 선택 직원 추가 체력 -10")
		apply_staff_extra_stamina_cost(10)


func apply_staff_extra_stamina_cost(stamina_cost: int) -> void:
	for staff_id in selected_staff_ids:
		var idx := get_staff_index(staff_id)
		if idx == -1:
			continue
		var current_stamina := int(staff[idx]["stamina"])
		var next_stamina: int = int(max(0, current_stamina - stamina_cost))
		staff[idx]["stamina"] = next_stamina
		if next_stamina <= 0:
			staff[idx]["injured"] = true
		result_lines.append("%s 추가 체력: %d -> %d%s" % [
			str(staff[idx]["name"]),
			current_stamina,
			next_stamina,
			" / 부상" if bool(staff[idx]["injured"]) else "",
		])


func apply_staff_stamina_cost(stamina_cost: int) -> void:
	for staff_id in selected_staff_ids:
		var idx := get_staff_index(staff_id)
		if idx == -1:
			continue
		var current_stamina := int(staff[idx]["stamina"])
		var next_stamina: int = int(max(0, current_stamina - stamina_cost))
		staff[idx]["stamina"] = next_stamina
		if next_stamina <= 0:
			staff[idx]["injured"] = true
		result_lines.append("%s 체력: %d -> %d%s" % [
			str(staff[idx]["name"]),
			current_stamina,
			next_stamina,
			" / 부상" if bool(staff[idx]["injured"]) else "",
		])


func check_failure() -> String:
	if money <= 0:
		return "F: 파산"
	if hell_trust <= 0:
		return "F: 마왕성 계약 해지"
	if illegal_risk >= 100:
		return "F: 불법 처리 적발"
	if are_all_staff_injured():
		return "F: 직원 전원 부상으로 운영 불가"
	return ""


func get_final_grade() -> String:
	if money <= 0:
		return "F: 파산한 청소업체"
	if hell_trust <= 0:
		return "F: 마왕성 계약 해지"
	if illegal_risk >= 100:
		return "F: 불법 처리 적발"
	if money >= 600 and hell_trust >= 70 and hygiene >= 75 and illegal_risk < 40:
		return "A: 마왕성 공인 우수 위생업체"
	if money >= 450 and hell_trust >= 50:
		return "B: 흑자 청소회사"
	if human_reputation >= 40 and illegal_risk >= 60:
		return "D: 인간 장물 브로커"
	return "C: 간신히 버틴 하청업체"


func are_all_staff_injured() -> bool:
	if staff.is_empty():
		return false
	for member in staff:
		if not bool(member["injured"]):
			return false
	return true


func calculate_team_score(primary_stat: String) -> int:
	var score := 0
	for staff_id in selected_staff_ids:
		var member := get_staff_by_id(staff_id)
		score += int(member.get(primary_stat, 0))
	for gear_id in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		if str(item.get("effect", "")) == primary_stat:
			score += int(item.get("power", 0))
	return score


func get_selected_gear_cost() -> int:
	var total := 0
	for gear_id in selected_gear_ids:
		var item := get_gear_by_id(gear_id)
		total += int(item.get("cost", 0))
	return total


func get_staff_index(staff_id: String) -> int:
	for i in range(staff.size()):
		if str(staff[i]["id"]) == staff_id:
			return i
	return -1


func get_staff_by_id(staff_id: String) -> Dictionary:
	var idx := get_staff_index(staff_id)
	if idx == -1:
		return {}
	return staff[idx]


func get_gear_by_id(gear_id: String) -> Dictionary:
	for item in gear:
		if str(item["id"]) == gear_id:
			return item
	return {}


func is_staff_injured(staff_id: String) -> bool:
	var member := get_staff_by_id(staff_id)
	return bool(member.get("injured", false))


func get_contract_summary(contract: Dictionary) -> String:
	return "%s | 의뢰인 %s | 보수 %d | 난이도 %d | 주요 능력 %s\n%s" % [
		str(contract["title"]),
		str(contract["client"]),
		int(contract["pay"]),
		int(contract["difficulty"]),
		get_stat_name(str(contract["primary_stat"])),
		str(contract["description"]),
	]


func get_option_delta_text(option: Dictionary) -> String:
	return "자금 %s | 마왕성 신뢰 %s | 인간 평판 %s | 위생 %s | 불법 리스크 %s | 체력 소모 %d" % [
		format_delta(int(option["money_bonus"])),
		format_delta(int(option["hell_trust"])),
		format_delta(int(option["human_reputation"])),
		format_delta(int(option["hygiene"])),
		format_delta(int(option["illegal_risk"])),
		int(option["stamina_cost"]),
	]


func format_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return "%d" % value


func get_stat_name(stat_id: String) -> String:
	match stat_id:
		"cleanup":
			return "청소"
		"pollution":
			return "오염 처리"
		"hauling":
			return "운반"
		"trap":
			return "함정"
	return stat_id


func get_gear_effect_name(effect_id: String) -> String:
	match effect_id:
		"pollution":
			return "오염 처리"
		"hauling":
			return "운반"
		"trap":
			return "함정"
		"human_profit":
			return "시체/유품 반환 수익"
		"illegal_profit":
			return "암시장 수익"
	return effect_id


func get_result_line_color(line: String) -> Color:
	if line.contains("실패") or line.contains("부상") or line.contains("(-") or line.contains(" -"):
		return COLOR_DANGER
	if line.contains("성공") or line.contains("+"):
		return COLOR_GREEN
	return COLOR_TEXT


func get_resolution_border_color(option_id: String) -> Color:
	match option_id:
		"proper_restore":
			return COLOR_GREEN
		"corpse_return":
			return COLOR_GOLD
		"black_market":
			return COLOR_PURPLE
		"cheap_cleanup":
			return COLOR_DANGER
	return COLOR_BORDER


func make_card(parent: Node, border_color: Color = COLOR_BORDER) -> VBoxContainer:
	var panel := make_panel_container(COLOR_PANEL, border_color, 2)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)
	return card


func make_panel_container(bg_color: Color, border_color: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", make_panel_style(bg_color, border_color, border_width))
	return panel


func make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(2)
	return style


func make_label(text: String, font_size: int, color: Color = COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button_style(button)
	return button


func apply_button_style(button: Button) -> void:
	UiAssetStyles.apply_plate_button_style(button)
