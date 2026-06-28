extends Node

signal changed

const INITIAL_DAY: int = 1
const INITIAL_MONEY: int = 300
const INITIAL_HELL_TRUST: int = 50
const INITIAL_HUMAN_REPUTATION: int = 10
const INITIAL_HYGIENE: int = 70
const INITIAL_ILLEGAL_RISK: int = 0

var day: int = INITIAL_DAY
var money: int = INITIAL_MONEY
var hell_trust: int = INITIAL_HELL_TRUST
var human_reputation: int = INITIAL_HUMAN_REPUTATION
var hygiene: int = INITIAL_HYGIENE
var illegal_risk: int = INITIAL_ILLEGAL_RISK
var last_report: String = ""


func reset() -> void:
	day = INITIAL_DAY
	money = INITIAL_MONEY
	hell_trust = INITIAL_HELL_TRUST
	human_reputation = INITIAL_HUMAN_REPUTATION
	hygiene = INITIAL_HYGIENE
	illegal_risk = INITIAL_ILLEGAL_RISK
	last_report = ""
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


func set_last_report(report: String) -> void:
	last_report = report
	changed.emit()


func format_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)
