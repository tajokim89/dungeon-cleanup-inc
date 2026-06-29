extends SceneTree

const GameStateScript = preload("res://scripts/GameState.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var state := GameStateScript.new()
	state.reset()
	_assert(state.select_contract("sewer_recovery"), "selects field contract")
	_assert(state.toggle_staff_selection("melta"), "selects pollution staff")
	_assert(state.toggle_staff_selection("pipit"), "selects trap staff")
	_assert(state.toggle_gear_selection("disinfect_slime"), "selects pollution gear")
	_assert(state.toggle_gear_selection("trap_kit"), "selects trap gear")

	var contract: Dictionary = state.get_selected_contract()
	_assert(state.get_contract_workload_hint(contract) == "많음", "shows workload as a rough hint")
	_assert(state.get_contract_primary_intel_hint(contract) == "오염 흔적 다수", "shows inferred contract intel instead of exact tasks")
	_assert(state.get_contract_intel_lines(contract).has("함정 파손 가능성"), "includes trap intel when contract has trap work")
	_assert(state.get_contract_uncertainty_lines(contract).has("방해 세력 가능성"), "includes possible combat as uncertain intel")
	var coverage_lines := state.get_contract_assignment_coverage_lines(contract)
	_assert(coverage_lines.has("오염 대응 충분"), "shows strong response for covered intel")
	_assert(coverage_lines.has("운반 대응 취약"), "shows weak response for uncovered intel")

	var tasks: Array = contract.get("tasks", [])
	for task: Dictionary in tasks:
		state.complete_field_task(task)

	var results: Array = state.get_field_task_results(contract)
	_assert(results.size() == tasks.size(), "stores each completed task result")
	_assert(state.get_field_task_grade_counts_text(results) == "우수 3 / 보통 0 / 미흡 3", "summarizes task grades")
	_assert(state.get_field_contract_grade_label(results, tasks.size()) == "C", "grades mixed field work")

	state.apply_contract_field_report(contract, tasks.size(), tasks.size())
	var report: Dictionary = state.get_last_settlement_report()
	_assert(String(report.get("contract_grade", "")) == "C", "settlement keeps contract grade")
	_assert(String(report.get("task_grade_counts_text", "")) == "우수 3 / 보통 0 / 미흡 3", "settlement keeps grade summary")
	_assert(Array(report.get("key_reason_lines", [])).size() <= 3, "settlement reasons stay compact")
	var feedback_lines: Array = report.get("field_feedback_lines", [])
	_assert(feedback_lines.has("오염 대응 적중"), "settlement reports matched field intel")
	_assert(feedback_lines.has("운반 대응 부족"), "settlement reports failed field intel")
	_assert(Dictionary(report.get("reward", {})).has("money"), "settlement includes reward deltas")
	_assert(int(state.get_staff_by_id("melta").get("stamina", 0)) == 68, "field work spends dispatched staff stamina")
	_assert(int(state.get_staff_by_id("grik").get("stamina", 0)) == 100, "idle staff keeps full stamina before recovery")

	state.advance_day_after_report()
	_assert(state.day == 2, "advances to the next day")
	_assert(int(state.get_staff_by_id("melta").get("stamina", 0)) == 73, "recently dispatched staff recovers 5 stamina")
	_assert(int(state.get_staff_by_id("pipit").get("stamina", 0)) == 73, "all recently dispatched staff recover 5 stamina")
	_assert(int(state.get_staff_by_id("grik").get("stamina", 0)) == 100, "idle staff recovery is capped at 100")
	_assert(int(state.get_staff_by_id("volg").get("stamina", 0)) == 100, "all idle staff recovery is capped at 100")

	state.free()
	if failures.is_empty():
		print("field_work_resolution_test passed")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
