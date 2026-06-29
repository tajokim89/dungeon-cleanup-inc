extends Node2D

const DUNGEON_TEST_SCENE_PATH: String = "res://scenes/DungeonTest.tscn"

const COLOR_BACKGROUND: Color = Color(0.063, 0.063, 0.078)
const COLOR_FLOOR: Color = Color(0.106, 0.106, 0.141)
const COLOR_WALL: Color = Color(0.208, 0.169, 0.118)
const COLOR_BOARD: Color = Color(0.357, 0.29, 0.2)
const COLOR_DESK: Color = Color(0.141, 0.141, 0.196)
const COLOR_DOOR: Color = Color(0.525, 0.722, 0.42)
const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)
const COLOR_PANEL: Color = Color(0.082, 0.086, 0.102)
const COLOR_PANEL_DARK: Color = Color(0.047, 0.052, 0.063)
const COLOR_MONEY: Color = Color(0.831, 0.694, 0.333)
const COLOR_TRUST: Color = Color(0.494, 0.686, 0.443)
const COLOR_REPUTATION: Color = Color(0.475, 0.608, 0.824)
const COLOR_HYGIENE: Color = Color(0.424, 0.718, 0.698)
const COLOR_RISK: Color = Color(0.788, 0.349, 0.318)

var player: PlayerController
var status_label: Label
var prompt_label: Label
var day_value_label: Label
var money_value_label: Label
var trust_value_label: Label
var reputation_value_label: Label
var hygiene_value_label: Label
var risk_value_label: Label
var contract_panel: PanelContainer
var contract_buttons: Array[Button] = []
var contract_selection_label: Label
var contract_detail_label: Label
var contract_dispatch_button: Button
var focused_contract_index: int = 0
var assignment_panel: PanelContainer
var assignment_buttons: Array[Button] = []
var assignment_staff_count_label: Label
var assignment_gear_count_label: Label
var assignment_summary_label: Label
var assignment_detail_label: Label
var focused_assignment_index: int = 0
var settlement_panel: PanelContainer
var settlement_title_label: Label
var settlement_result_label: Label
var settlement_assignment_label: Label
var settlement_changes_label: Label
var settlement_staff_label: Label
var settlement_footer_label: Label
var settlement_next_day_button: Button


func _ready() -> void:
	build_office()
	var game_state_changed_callback: Callable = Callable(self, "_on_game_state_changed")
	if not GameState.changed.is_connected(game_state_changed_callback):
		GameState.changed.connect(game_state_changed_callback)
	refresh_hud()
	refresh_contract_board()
	refresh_assignment_panel()
	if GameState.last_report == "":
		status_label.text = "사무실 허브 테스트: WASD로 이동"
	else:
		status_label.text = GameState.last_report
	prompt_label.text = "오브젝트 근처에서 E / Space"
	if GameState.has_last_settlement_report():
		call_deferred("open_settlement_report")


func build_office() -> void:
	create_background()
	create_room()
	create_interactables()
	create_player()
	create_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if contract_panel != null and contract_panel.visible:
				handle_contract_board_key(key_event.keycode)
				get_viewport().set_input_as_handled()
				return
			if assignment_panel != null and assignment_panel.visible:
				handle_assignment_panel_key(key_event.keycode)
				get_viewport().set_input_as_handled()
				return


func create_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = COLOR_BACKGROUND
	background.position = Vector2.ZERO
	background.size = Vector2(1270, 720)
	add_child(background)


func create_room() -> void:
	create_rect("Floor", Rect2(Vector2(150, 168), Vector2(970, 432)), COLOR_FLOOR)
	create_wall("NorthWall", Rect2(Vector2(150, 168), Vector2(970, 28)))
	create_wall("SouthWall", Rect2(Vector2(150, 572), Vector2(970, 28)))
	create_wall("WestWall", Rect2(Vector2(150, 168), Vector2(28, 432)))
	create_wall("EastWall", Rect2(Vector2(1092, 168), Vector2(28, 432)))


func create_interactables() -> void:
	create_interactable(
		"ContractBoard",
		"의뢰 게시판",
		"오늘 접수된 던전 복구 의뢰를 확인합니다.",
		Vector2(300, 232),
		Vector2(150, 52),
		COLOR_BOARD
	)
	create_interactable(
		"StaffDesk",
		"직원 책상",
		"출동할 직원을 편성합니다.",
		Vector2(520, 260),
		Vector2(150, 74),
		COLOR_DESK
	)
	create_interactable(
		"GearShelf",
		"장비 선반",
		"소독 점액통, 사체 포대, 함정 수리 키트를 챙길 수 있습니다.",
		Vector2(790, 252),
		Vector2(170, 64),
		COLOR_DESK
	)
	create_interactable(
		"Ledger",
		"회사 장부",
		"회사 상태를 확인합니다.",
		Vector2(365, 495),
		Vector2(130, 70),
		Color(0.18, 0.12, 0.18)
	)
	create_interactable(
		"DispatchDoor",
		"출동문",
		"선택한 의뢰 현장으로 출동합니다.",
		Vector2(980, 492),
		Vector2(84, 130),
		COLOR_DOOR
	)


func create_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.position = Vector2(635, 386)

	var sprite := AnimatedSprite2D.new()
	sprite.name = "BossSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.15, 1.15)
	player.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 40)
	collision.shape = shape
	player.add_child(collision)

	var interaction_area := Area2D.new()
	interaction_area.name = "InteractionArea"
	player.add_child(interaction_area)

	var interaction_shape := CollisionShape2D.new()
	var interaction_circle := CircleShape2D.new()
	interaction_circle.radius = 52.0
	interaction_shape.shape = interaction_circle
	interaction_area.add_child(interaction_shape)

	add_child(player)
	player.interaction_target_changed.connect(_on_interaction_target_changed)
	player.interaction_requested.connect(_on_player_interaction_requested)


func create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.offset_left = 24
	panel.offset_top = 20
	panel.offset_right = 1088
	panel.offset_bottom = 148
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_BOARD, 2))
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := make_label("던전 클린업 주식회사", 19, COLOR_GOLD)
	title_box.add_child(title)

	var subtitle := make_label("몬스터 측 던전 복구 및 위생 관리업체", 12, COLOR_MUTED)
	title_box.add_child(subtitle)

	var office_badge := make_badge("사무실")
	header.add_child(office_badge)

	var stat_row := HBoxContainer.new()
	stat_row.name = "StatRow"
	stat_row.add_theme_constant_override("separation", 8)
	layout.add_child(stat_row)

	day_value_label = create_stat_chip(stat_row, "DAY", COLOR_GOLD, 84.0)
	money_value_label = create_stat_chip(stat_row, "자금", COLOR_MONEY, 120.0)
	trust_value_label = create_stat_chip(stat_row, "마왕성 신뢰", COLOR_TRUST, 144.0)
	reputation_value_label = create_stat_chip(stat_row, "인간 평판", COLOR_REPUTATION, 128.0)
	hygiene_value_label = create_stat_chip(stat_row, "위생", COLOR_HYGIENE, 112.0)
	risk_value_label = create_stat_chip(stat_row, "불법 리스크", COLOR_RISK, 132.0)

	create_message_panel(canvas)
	create_contract_board_panel(canvas)
	create_assignment_panel(canvas)
	create_settlement_report_panel(canvas)


func create_message_panel(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "MessagePanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24
	panel.offset_top = -112
	panel.offset_right = -24
	panel.offset_bottom = -20
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_BOARD, 2))
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var message_layout := VBoxContainer.new()
	message_layout.add_theme_constant_override("separation", 6)
	margin.add_child(message_layout)

	status_label = make_label("", 18, COLOR_TEXT)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.custom_minimum_size = Vector2(0.0, 28.0)
	prompt_label = make_label("", 16, COLOR_GOLD)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.custom_minimum_size = Vector2(0.0, 24.0)

	message_layout.add_child(status_label)
	message_layout.add_child(prompt_label)


func create_contract_board_panel(canvas: CanvasLayer) -> void:
	contract_panel = PanelContainer.new()
	contract_panel.name = "ContractBoardPanel"
	contract_panel.visible = false
	contract_panel.anchor_left = 0.5
	contract_panel.anchor_top = 0.5
	contract_panel.anchor_right = 0.5
	contract_panel.anchor_bottom = 0.5
	contract_panel.offset_left = -390
	contract_panel.offset_top = -225
	contract_panel.offset_right = 390
	contract_panel.offset_bottom = 225
	contract_panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_GOLD, 2))
	canvas.add_child(contract_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	contract_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title := make_label("의뢰 게시판", 20, COLOR_GOLD)
	title_box.add_child(title)

	contract_selection_label = make_label("", 13, COLOR_MUTED)
	title_box.add_child(contract_selection_label)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(82.0, 34.0)
	close_button.pressed.connect(close_contract_board)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_box.custom_minimum_size = Vector2(285.0, 0.0)
	body.add_child(list_box)

	for contract: Dictionary in GameState.get_field_contracts():
		var contract_id := String(contract.get("id", ""))
		var button := Button.new()
		button.text = String(contract.get("title", "의뢰"))
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(285.0, 48.0)
		button.set_meta("contract_id", contract_id)
		button.pressed.connect(_on_contract_button_pressed.bind(contract_id))
		contract_buttons.append(button)
		list_box.add_child(button)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 12)
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_box)

	contract_detail_label = make_label("", 15, COLOR_TEXT)
	contract_detail_label.custom_minimum_size = Vector2(0.0, 210.0)
	contract_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(contract_detail_label)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 8)
	detail_box.add_child(action_row)

	var choose_hint := make_label("계약서 검토", 13, COLOR_MUTED)
	choose_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(choose_hint)

	contract_dispatch_button = Button.new()
	contract_dispatch_button.text = "출동"
	contract_dispatch_button.focus_mode = Control.FOCUS_NONE
	contract_dispatch_button.custom_minimum_size = Vector2(110.0, 36.0)
	contract_dispatch_button.pressed.connect(go_to_dungeon)
	action_row.add_child(contract_dispatch_button)


func create_assignment_panel(canvas: CanvasLayer) -> void:
	assignment_panel = PanelContainer.new()
	assignment_panel.name = "AssignmentPanel"
	assignment_panel.visible = false
	assignment_panel.anchor_left = 0.5
	assignment_panel.anchor_top = 0.5
	assignment_panel.anchor_right = 0.5
	assignment_panel.anchor_bottom = 0.5
	assignment_panel.offset_left = -500
	assignment_panel.offset_top = -255
	assignment_panel.offset_right = 500
	assignment_panel.offset_bottom = 245
	assignment_panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_REPUTATION, 2))
	canvas.add_child(assignment_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	assignment_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title := make_label("출동 편성", 20, COLOR_GOLD)
	title_box.add_child(title)

	assignment_summary_label = make_label("", 13, COLOR_MUTED)
	title_box.add_child(assignment_summary_label)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(82.0, 34.0)
	close_button.pressed.connect(close_assignment_panel)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var staff_column := VBoxContainer.new()
	staff_column.add_theme_constant_override("separation", 6)
	staff_column.custom_minimum_size = Vector2(245.0, 0.0)
	body.add_child(staff_column)

	assignment_staff_count_label = make_label("", 15, COLOR_GOLD)
	staff_column.add_child(assignment_staff_count_label)

	for member: Dictionary in GameState.get_staff_roster():
		var staff_id := String(member.get("id", ""))
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(245.0, 58.0)
		button.set_meta("item_type", "staff")
		button.set_meta("item_id", staff_id)
		button.pressed.connect(_on_assignment_staff_pressed.bind(staff_id))
		assignment_buttons.append(button)
		staff_column.add_child(button)

	var gear_column := VBoxContainer.new()
	gear_column.add_theme_constant_override("separation", 6)
	gear_column.custom_minimum_size = Vector2(245.0, 0.0)
	body.add_child(gear_column)

	assignment_gear_count_label = make_label("", 15, COLOR_GOLD)
	gear_column.add_child(assignment_gear_count_label)

	for item: Dictionary in GameState.get_gear_inventory():
		var gear_id := String(item.get("id", ""))
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(245.0, 50.0)
		button.set_meta("item_type", "gear")
		button.set_meta("item_id", gear_id)
		button.pressed.connect(_on_assignment_gear_pressed.bind(gear_id))
		assignment_buttons.append(button)
		gear_column.add_child(button)

	var dispatch_button := Button.new()
	dispatch_button.focus_mode = Control.FOCUS_NONE
	dispatch_button.custom_minimum_size = Vector2(245.0, 42.0)
	dispatch_button.set_meta("item_type", "dispatch")
	dispatch_button.set_meta("item_id", "")
	dispatch_button.pressed.connect(go_to_dungeon)
	assignment_buttons.append(dispatch_button)
	gear_column.add_child(dispatch_button)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 12)
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_box)

	assignment_detail_label = make_label("", 15, COLOR_TEXT)
	assignment_detail_label.custom_minimum_size = Vector2(0.0, 390.0)
	assignment_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assignment_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(assignment_detail_label)


func create_settlement_report_panel(canvas: CanvasLayer) -> void:
	settlement_panel = PanelContainer.new()
	settlement_panel.name = "SettlementReportPanel"
	settlement_panel.visible = false
	settlement_panel.anchor_left = 0.5
	settlement_panel.anchor_top = 0.5
	settlement_panel.anchor_right = 0.5
	settlement_panel.anchor_bottom = 0.5
	settlement_panel.offset_left = -460
	settlement_panel.offset_top = -250
	settlement_panel.offset_right = 460
	settlement_panel.offset_bottom = 250
	settlement_panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_TRUST, 2))
	canvas.add_child(settlement_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	settlement_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title := make_label("현장 정산 보고", 20, COLOR_GOLD)
	title_box.add_child(title)

	settlement_title_label = make_label("", 13, COLOR_MUTED)
	title_box.add_child(settlement_title_label)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(82.0, 34.0)
	close_button.pressed.connect(close_settlement_report)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 8)
	left_column.custom_minimum_size = Vector2(430.0, 0.0)
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left_column)

	settlement_result_label = create_report_block(left_column, "작업 결과", Vector2(0.0, 92.0))
	settlement_assignment_label = create_report_block(left_column, "출동 편성", Vector2(0.0, 188.0))

	var right_column := VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 8)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_column)

	settlement_changes_label = create_report_block(right_column, "정산 변화", Vector2(0.0, 160.0))
	settlement_staff_label = create_report_block(right_column, "직원 상태", Vector2(0.0, 120.0))

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 8)
	layout.add_child(action_row)

	settlement_footer_label = make_label("장부에서 최근 정산을 다시 확인할 수 있습니다.", 13, COLOR_MUTED)
	settlement_footer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(settlement_footer_label)

	settlement_next_day_button = Button.new()
	settlement_next_day_button.text = "다음 날"
	settlement_next_day_button.focus_mode = Control.FOCUS_NONE
	settlement_next_day_button.custom_minimum_size = Vector2(110.0, 36.0)
	settlement_next_day_button.pressed.connect(_on_next_day_pressed)
	action_row.add_child(settlement_next_day_button)


func create_report_block(parent: VBoxContainer, heading: String, min_size: Vector2) -> Label:
	var heading_label := make_label(heading, 15, COLOR_GOLD)
	heading_label.custom_minimum_size = Vector2(0.0, 20.0)
	parent.add_child(heading_label)

	var body_label := make_label("", 14, COLOR_TEXT)
	body_label.custom_minimum_size = min_size
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(body_label)
	return body_label


func create_wall(node_name: String, rect: Rect2) -> void:
	create_rect("%sVisual" % node_name, rect, COLOR_WALL)

	var wall := StaticBody2D.new()
	wall.name = node_name
	wall.position = rect.position + rect.size * 0.5
	add_child(wall)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	wall.add_child(collision)


func create_interactable(node_name: String, label: String, action: String, position: Vector2, size: Vector2, color: Color) -> void:
	create_rect("%sVisual" % node_name, Rect2(position - size * 0.5, size), color)
	create_text_label("%sLabel" % node_name, label, position + Vector2(-size.x * 0.5, -size.y * 0.5 - 26), size.x)

	var interactable := Interactable.new()
	interactable.name = node_name
	interactable.label = label
	interactable.action = action
	interactable.position = position
	interactable.add_to_group("interactable")
	interactable.interacted.connect(_on_interactable_interacted)
	add_child(interactable)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	interactable.add_child(collision)


func create_rect(node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	add_child(color_rect)
	return color_rect


func create_text_label(node_name: String, text: String, position: Vector2, width: float) -> Label:
	var label := make_label(text, 14, COLOR_GOLD)
	label.name = node_name
	label.position = position
	label.size = Vector2(width, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(2)
	return style


func create_stat_chip(parent: HBoxContainer, caption: String, accent_color: Color, width: float) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 48.0)
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL_DARK, accent_color, 1))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 1)
	margin.add_child(layout)

	var caption_label := make_label(caption, 11, COLOR_MUTED)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(caption_label)

	var value_label := make_label("", 18, accent_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(value_label)
	return value_label


func make_badge(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(78.0, 30.0)
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL_DARK, COLOR_GOLD, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var label := make_label(text, 13, COLOR_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(label)
	return panel


func open_contract_board() -> void:
	if contract_panel == null:
		return

	sync_contract_focus_with_selection()
	refresh_contract_board()
	contract_panel.visible = true
	sync_player_control_with_modals()


func close_contract_board() -> void:
	if contract_panel != null:
		contract_panel.visible = false

	sync_player_control_with_modals()


func open_assignment_panel() -> void:
	if assignment_panel == null:
		return

	sync_assignment_focus()
	refresh_assignment_panel()
	assignment_panel.visible = true
	sync_player_control_with_modals()


func close_assignment_panel() -> void:
	if assignment_panel != null:
		assignment_panel.visible = false

	sync_player_control_with_modals()


func open_settlement_report() -> void:
	if settlement_panel == null:
		return

	refresh_settlement_report()
	settlement_panel.visible = true
	sync_player_control_with_modals()


func close_settlement_report() -> void:
	if settlement_panel != null:
		settlement_panel.visible = false

	sync_player_control_with_modals()


func sync_player_control_with_modals() -> void:
	if player != null:
		var modal_open := false
		if contract_panel != null and contract_panel.visible:
			modal_open = true
		if assignment_panel != null and assignment_panel.visible:
			modal_open = true
		if settlement_panel != null and settlement_panel.visible:
			modal_open = true
		player.set_physics_process(not modal_open)
		player.set_process_unhandled_input(not modal_open)


func handle_contract_board_key(keycode: Key) -> void:
	match keycode:
		KEY_ESCAPE:
			close_contract_board()
		KEY_E, KEY_SPACE, KEY_ENTER:
			select_focused_contract()
		KEY_UP, KEY_W, KEY_LEFT, KEY_A:
			move_contract_focus(-1)
		KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D:
			move_contract_focus(1)


func move_contract_focus(direction: int) -> void:
	if contract_buttons.is_empty():
		return

	focused_contract_index = wrapi(focused_contract_index + direction, 0, contract_buttons.size())
	refresh_contract_board()


func select_focused_contract() -> void:
	var contract_id := get_focused_contract_id()
	if contract_id.is_empty():
		return

	_on_contract_button_pressed(contract_id)


func handle_assignment_panel_key(keycode: Key) -> void:
	match keycode:
		KEY_ESCAPE:
			close_assignment_panel()
		KEY_E, KEY_SPACE, KEY_ENTER:
			select_focused_assignment_item()
		KEY_UP, KEY_W, KEY_LEFT, KEY_A:
			move_assignment_focus(-1)
		KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D:
			move_assignment_focus(1)


func move_assignment_focus(direction: int) -> void:
	if assignment_buttons.is_empty():
		return

	focused_assignment_index = wrapi(focused_assignment_index + direction, 0, assignment_buttons.size())
	refresh_assignment_panel()


func select_focused_assignment_item() -> void:
	var button := get_focused_assignment_button()
	if button == null:
		return

	var item_type := String(button.get_meta("item_type", ""))
	var item_id := String(button.get_meta("item_id", ""))
	match item_type:
		"staff":
			_on_assignment_staff_pressed(item_id)
		"gear":
			_on_assignment_gear_pressed(item_id)
		"dispatch":
			go_to_dungeon()


func sync_assignment_focus() -> void:
	if assignment_buttons.is_empty():
		focused_assignment_index = 0
		return

	focused_assignment_index = clampi(focused_assignment_index, 0, assignment_buttons.size() - 1)


func get_focused_assignment_button() -> Button:
	if assignment_buttons.is_empty():
		return null

	focused_assignment_index = clampi(focused_assignment_index, 0, assignment_buttons.size() - 1)
	return assignment_buttons[focused_assignment_index]


func sync_contract_focus_with_selection() -> void:
	if contract_buttons.is_empty():
		focused_contract_index = 0
		return

	var selected_contract := GameState.get_selected_contract()
	var selected_id := String(selected_contract.get("id", ""))
	if selected_id.is_empty():
		focused_contract_index = clampi(focused_contract_index, 0, contract_buttons.size() - 1)
		return

	for index in range(contract_buttons.size()):
		if String(contract_buttons[index].get_meta("contract_id", "")) == selected_id:
			focused_contract_index = index
			return

	focused_contract_index = clampi(focused_contract_index, 0, contract_buttons.size() - 1)


func get_focused_contract_id() -> String:
	if contract_buttons.is_empty():
		return ""

	focused_contract_index = clampi(focused_contract_index, 0, contract_buttons.size() - 1)
	return String(contract_buttons[focused_contract_index].get_meta("contract_id", ""))


func get_focused_contract() -> Dictionary:
	var contract_id := get_focused_contract_id()
	if contract_id.is_empty():
		return {}
	return GameState.get_contract_by_id(contract_id)


func refresh_contract_board() -> void:
	if contract_selection_label == null or contract_detail_label == null:
		return

	var selected_contract := GameState.get_selected_contract()
	var selected_id := String(selected_contract.get("id", ""))
	var focused_contract := get_focused_contract()
	if selected_contract.is_empty():
		contract_selection_label.text = "선택된 의뢰 없음"
		if contract_dispatch_button != null:
			contract_dispatch_button.disabled = true
	else:
		contract_selection_label.text = "선택: %s" % String(selected_contract.get("title", "의뢰"))
		if contract_dispatch_button != null:
			contract_dispatch_button.disabled = false

	if focused_contract.is_empty():
		contract_detail_label.text = "접수된 현장 의뢰 %d건\n\n현장 정보 대기" % GameState.get_field_contracts().size()
	else:
		contract_detail_label.text = get_contract_detail_text(focused_contract)

	for index in range(contract_buttons.size()):
		var button := contract_buttons[index]
		var contract_id := String(button.get_meta("contract_id", ""))
		var contract := GameState.get_contract_by_id(contract_id)
		var prefix := ""
		if index == focused_contract_index:
			prefix += "> "
		if contract_id == selected_id:
			prefix += "[선택] "
		button.text = "%s%s" % [prefix, String(contract.get("title", "의뢰"))]


func refresh_assignment_panel() -> void:
	if assignment_summary_label == null or assignment_detail_label == null:
		return

	var selected_staff_ids := GameState.get_selected_staff_ids()
	var selected_gear_ids := GameState.get_selected_gear_ids()
	assignment_summary_label.text = "직원 %d/%d | 장비 %d/%d | 장비 비용 %d" % [
		selected_staff_ids.size(),
		GameState.STAFF_SELECTION_LIMIT,
		selected_gear_ids.size(),
		GameState.GEAR_SELECTION_LIMIT,
		GameState.get_selected_gear_cost()
	]
	assignment_staff_count_label.text = "직원 선택 %d/%d" % [
		selected_staff_ids.size(),
		GameState.STAFF_SELECTION_LIMIT
	]
	assignment_gear_count_label.text = "장비 선택 %d/%d" % [
		selected_gear_ids.size(),
		GameState.GEAR_SELECTION_LIMIT
	]
	assignment_detail_label.text = get_assignment_detail_text()

	for index in range(assignment_buttons.size()):
		var button := assignment_buttons[index]
		var item_type := String(button.get_meta("item_type", ""))
		var item_id := String(button.get_meta("item_id", ""))
		var prefix := "> " if index == focused_assignment_index else ""

		match item_type:
			"staff":
				var member := GameState.get_staff_by_id(item_id)
				var staff_selected := GameState.is_staff_selected(item_id)
				var injured := bool(member.get("injured", false))
				button.disabled = not staff_selected and (injured or selected_staff_ids.size() >= GameState.STAFF_SELECTION_LIMIT)
				button.text = "%s%s%s  체력 %d%s\n청%d 오%d 운%d 함%d" % [
					prefix,
					"[선택] " if staff_selected else "",
					String(member.get("name", item_id)),
					int(member.get("stamina", 0)),
					" / 부상" if injured else "",
					int(member.get("cleanup", 0)),
					int(member.get("pollution", 0)),
					int(member.get("hauling", 0)),
					int(member.get("trap", 0))
				]
			"gear":
				var item := GameState.get_gear_by_id(item_id)
				var gear_selected := GameState.is_gear_selected(item_id)
				button.disabled = not gear_selected and selected_gear_ids.size() >= GameState.GEAR_SELECTION_LIMIT
				button.text = "%s%s%s  비용 %d\n%s" % [
					prefix,
					"[선택] " if gear_selected else "",
					String(item.get("name", item_id)),
					int(item.get("cost", 0)),
					GameState.get_gear_effect_text(item)
				]
			"dispatch":
				var blocker := GameState.get_dispatch_blocker()
				button.disabled = not blocker.is_empty()
				button.text = "%s%s" % [
					prefix,
					"출동" if blocker.is_empty() else "출동 준비 미완료"
				]


func get_assignment_detail_text() -> String:
	var lines: Array[String] = []
	lines.append("선택 항목")
	lines.append("  %s" % get_focused_assignment_detail_text())
	lines.append("")

	var selected_contract := GameState.get_selected_contract()
	if selected_contract.is_empty():
		lines.append("선택 의뢰")
		lines.append("  아직 선택된 의뢰가 없습니다.")
	else:
		var primary_stat := GameState.get_contract_primary_stat(selected_contract)
		var team_score := GameState.calculate_assignment_score(primary_stat)
		var required_score := GameState.get_contract_required_score(selected_contract)
		lines.append("선택 의뢰")
		lines.append("  %s" % String(selected_contract.get("title", "의뢰")))
		lines.append("  %s" % String(selected_contract.get("location", "현장")))
		lines.append("  필요 능력: %s %d/%d" % [
			GameState.get_stat_name(primary_stat),
			team_score,
			required_score
		])

	lines.append("")
	lines.append("편성 요약")
	lines.append("  직원: %s" % GameState.get_selected_staff_names_text())
	lines.append("  장비: %s" % GameState.get_selected_gear_names_text())
	lines.append("  장비 비용: %d" % GameState.get_selected_gear_cost())

	var blocker := GameState.get_dispatch_blocker()
	lines.append("")
	lines.append("출동 상태")
	lines.append("  준비 완료" if blocker.is_empty() else "  %s" % blocker)
	return "\n".join(lines)


func get_focused_assignment_detail_text() -> String:
	var button := get_focused_assignment_button()
	if button == null:
		return "항목 없음"

	var item_type := String(button.get_meta("item_type", ""))
	var item_id := String(button.get_meta("item_id", ""))
	match item_type:
		"staff":
			var member := GameState.get_staff_by_id(item_id)
			return "%s / %s\n  역할: %s\n  능력: 청소 %d, 오염 %d, 운반 %d, 함정 %d" % [
				String(member.get("name", item_id)),
				String(member.get("species", "")),
				String(member.get("role", "")),
				int(member.get("cleanup", 0)),
				int(member.get("pollution", 0)),
				int(member.get("hauling", 0)),
				int(member.get("trap", 0))
			]
		"gear":
			var item := GameState.get_gear_by_id(item_id)
			return "%s\n  비용: %d\n  효과: %s" % [
				String(item.get("name", item_id)),
				int(item.get("cost", 0)),
				GameState.get_gear_effect_text(item)
			]
		"dispatch":
			var blocker := GameState.get_dispatch_blocker()
			return "출동\n  %s" % ("준비 완료" if blocker.is_empty() else blocker)
		_:
			return "항목 없음"


func refresh_settlement_report() -> void:
	if settlement_title_label == null or settlement_result_label == null:
		return

	var report := GameState.get_last_settlement_report()
	if report.is_empty():
		settlement_title_label.text = "정산 대기"
		settlement_result_label.text = "아직 보고할 현장 결과가 없습니다."
		settlement_assignment_label.text = ""
		settlement_changes_label.text = ""
		settlement_staff_label.text = ""
		if settlement_footer_label != null:
			settlement_footer_label.text = "현장을 마치면 정산 보고가 표시됩니다."
		if settlement_next_day_button != null:
			settlement_next_day_button.disabled = true
		return

	if settlement_next_day_button != null:
		settlement_next_day_button.disabled = false
	if settlement_footer_label != null:
		settlement_footer_label.text = "보고 확인 후 다음 날로 진행합니다."

	var contract_title := String(report.get("contract_title", "현장"))
	var location := String(report.get("location", ""))
	var completed_count := int(report.get("completed_count", 0))
	var total_count := int(report.get("total_count", 0))
	var battle_resolved := bool(report.get("battle_resolved", false))
	var battle_text := String(report.get("battle_report", ""))
	var before: Dictionary = report.get("before", {})
	var after: Dictionary = report.get("after", {})
	var reward: Dictionary = report.get("reward", {})
	var assignment_lines: Array = report.get("assignment_lines", [])
	var staff_changes: Array = report.get("staff_changes", [])

	settlement_title_label.text = "%s / %s" % [contract_title, location]
	settlement_result_label.text = "\n".join([
		"현장 작업  %d/%d 완료" % [completed_count, total_count],
		"전투 이벤트  %s" % ("해결" if battle_resolved else "없음 또는 미해결"),
		"전투 보고  %s" % compact_report_text(battle_text, "기록 없음", 34)
	])

	if assignment_lines.is_empty():
		settlement_assignment_label.text = "편성 기록 없음"
	else:
		settlement_assignment_label.text = compact_lines(assignment_lines, 7, 44)

	settlement_changes_label.text = "\n".join([
		format_settlement_change("자금", "money", before, after, reward),
		format_settlement_change("마왕성 신뢰", "hell_trust", before, after, reward),
		format_settlement_change("인간 평판", "human_reputation", before, after, reward),
		format_settlement_change("위생", "hygiene", before, after, reward),
		format_settlement_change("불법 리스크", "illegal_risk", before, after, reward)
	])

	if staff_changes.is_empty():
		settlement_staff_label.text = "피로 변화 없음"
	else:
		settlement_staff_label.text = compact_lines(staff_changes, 4, 38)


func format_settlement_change(label: String, key: String, before: Dictionary, after: Dictionary, reward: Dictionary) -> String:
	var before_value := int(before.get(key, 0))
	var after_value := int(after.get(key, 0))
	var delta := int(reward.get(key, after_value - before_value))
	return "%s  %d -> %d (%s)" % [label, before_value, after_value, GameState.format_delta(delta)]


func compact_lines(raw_lines: Array, max_lines: int, max_chars: int) -> String:
	var lines: Array[String] = []
	for raw_line in raw_lines:
		if lines.size() >= max_lines:
			break
		lines.append(compact_report_text(String(raw_line), "", max_chars))

	var remaining_count := raw_lines.size() - lines.size()
	if remaining_count > 0:
		lines.append("외 %d개 항목" % remaining_count)
	return "\n".join(lines)


func compact_report_text(text: String, fallback: String, max_chars: int) -> String:
	var value := text.strip_edges()
	if value.is_empty():
		value = fallback
	if value.length() <= max_chars:
		return value
	return "%s..." % value.substr(0, max_chars - 3)


func get_contract_detail_text(contract: Dictionary) -> String:
	var tasks: Array = contract.get("tasks", [])
	return "%s\n%s\n\n의뢰처: %s\n현장: %s\n작업: %d개\n보상: %s" % [
		String(contract.get("title", "의뢰")),
		String(contract.get("summary", "")),
		String(contract.get("client", "")),
		String(contract.get("location", "")),
		tasks.size(),
		GameState.get_reward_text(contract)
	]


func _on_contract_button_pressed(contract_id: String) -> void:
	for index in range(contract_buttons.size()):
		if String(contract_buttons[index].get_meta("contract_id", "")) == contract_id:
			focused_contract_index = index
			break

	if not GameState.select_contract(contract_id):
		status_label.text = "의뢰 선택에 실패했습니다."
		return

	var contract := GameState.get_selected_contract()
	status_label.text = "의뢰 선택: %s" % String(contract.get("title", "의뢰"))
	refresh_contract_board()
	refresh_assignment_panel()


func _on_assignment_staff_pressed(staff_id: String) -> void:
	if GameState.toggle_staff_selection(staff_id):
		status_label.text = "직원 편성: %s" % GameState.get_selected_staff_names_text()
	else:
		status_label.text = "직원 선택 불가: 부상 상태이거나 최대 %d명까지 편성할 수 있습니다." % GameState.STAFF_SELECTION_LIMIT
	refresh_assignment_panel()


func _on_assignment_gear_pressed(gear_id: String) -> void:
	if GameState.toggle_gear_selection(gear_id):
		status_label.text = "장비 선택: %s" % GameState.get_selected_gear_names_text()
	else:
		status_label.text = "장비 선택 불가: 최대 %d개까지 챙길 수 있습니다." % GameState.GEAR_SELECTION_LIMIT
	refresh_assignment_panel()


func _on_interaction_target_changed(label: String) -> void:
	if label == "":
		prompt_label.text = "오브젝트 근처에서 E / Space"
	else:
		prompt_label.text = "E/Space: %s" % label


func _on_player_interaction_requested(target: Interactable) -> void:
	var target_name := String(target.name)
	if target_name == "ContractBoard":
		open_contract_board()
		return

	if target_name == "Ledger" and GameState.has_last_settlement_report():
		open_settlement_report()
		return

	if target_name == "StaffDesk" or target_name == "GearShelf":
		open_assignment_panel()
		return

	if target_name == "DispatchDoor":
		call_deferred("go_to_dungeon")


func _on_interactable_interacted(label: String, action: String) -> void:
	if label == "의뢰 게시판":
		status_label.text = "%s: 접수된 현장 의뢰를 확인합니다." % label
		return

	if label == "회사 장부":
		if GameState.has_last_settlement_report():
			status_label.text = "%s: 최근 현장 정산 보고서를 확인합니다." % label
			open_settlement_report()
		else:
			status_label.text = "%s: %s" % [label, GameState.get_company_status_text()]
		return

	status_label.text = "%s: %s" % [label, action]


func _on_game_state_changed() -> void:
	refresh_hud()
	refresh_contract_board()
	refresh_assignment_panel()
	if settlement_panel != null and settlement_panel.visible:
		refresh_settlement_report()


func refresh_hud() -> void:
	day_value_label.text = str(GameState.day)
	money_value_label.text = str(GameState.money)
	trust_value_label.text = str(GameState.hell_trust)
	reputation_value_label.text = str(GameState.human_reputation)
	hygiene_value_label.text = str(GameState.hygiene)
	risk_value_label.text = str(GameState.illegal_risk)


func go_to_dungeon() -> void:
	var dispatch_blocker := GameState.get_dispatch_blocker()
	if not dispatch_blocker.is_empty():
		status_label.text = dispatch_blocker
		if not GameState.has_selected_contract():
			close_assignment_panel()
			open_contract_board()
		else:
			close_contract_board()
			open_assignment_panel()
		return

	if not GameState.has_selected_contract():
		status_label.text = "출동할 의뢰를 먼저 선택하세요."
		open_contract_board()
		return

	close_contract_board()
	close_assignment_panel()
	close_settlement_report()
	get_tree().change_scene_to_file(DUNGEON_TEST_SCENE_PATH)


func _on_next_day_pressed() -> void:
	GameState.advance_day_after_report()
	close_settlement_report()
	status_label.text = GameState.last_report
	refresh_hud()
