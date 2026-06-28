extends Node2D

const BossTexture = preload("res://assets/sprites/boss_placeholder.svg")
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


func _ready() -> void:
	build_office()
	var game_state_changed_callback: Callable = Callable(self, "_on_game_state_changed")
	if not GameState.changed.is_connected(game_state_changed_callback):
		GameState.changed.connect(game_state_changed_callback)
	refresh_hud()
	refresh_contract_board()
	if GameState.last_report == "":
		status_label.text = "사무실 허브 테스트: WASD로 이동"
	else:
		status_label.text = GameState.last_report
	prompt_label.text = "오브젝트 근처에서 E / Space"


func build_office() -> void:
	create_background()
	create_room()
	create_interactables()
	create_player()
	create_ui()


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
		"출동할 직원 편성 자리입니다. 지금은 상호작용 테스트만 합니다.",
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

	var sprite := Sprite2D.new()
	sprite.name = "BossSprite"
	sprite.texture = BossTexture
	sprite.scale = Vector2(2.0, 2.0)
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
	contract_dispatch_button.custom_minimum_size = Vector2(110.0, 36.0)
	contract_dispatch_button.pressed.connect(go_to_dungeon)
	action_row.add_child(contract_dispatch_button)


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

	refresh_contract_board()
	contract_panel.visible = true
	if player != null:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)


func close_contract_board() -> void:
	if contract_panel != null:
		contract_panel.visible = false

	if player != null:
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)


func refresh_contract_board() -> void:
	if contract_selection_label == null or contract_detail_label == null:
		return

	var selected_contract := GameState.get_selected_contract()
	var selected_id := String(selected_contract.get("id", ""))
	if selected_contract.is_empty():
		contract_selection_label.text = "선택된 의뢰 없음"
		contract_detail_label.text = "접수된 현장 의뢰 %d건\n\n현장 정보 대기" % GameState.get_field_contracts().size()
		if contract_dispatch_button != null:
			contract_dispatch_button.disabled = true
	else:
		contract_selection_label.text = "선택: %s" % String(selected_contract.get("title", "의뢰"))
		contract_detail_label.text = get_contract_detail_text(selected_contract)
		if contract_dispatch_button != null:
			contract_dispatch_button.disabled = false

	for button: Button in contract_buttons:
		var contract_id := String(button.get_meta("contract_id", ""))
		var contract := GameState.get_contract_by_id(contract_id)
		var prefix := "[선택] " if contract_id == selected_id else ""
		button.text = "%s%s" % [prefix, String(contract.get("title", "의뢰"))]


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
	if not GameState.select_contract(contract_id):
		status_label.text = "의뢰 선택에 실패했습니다."
		return

	var contract := GameState.get_selected_contract()
	status_label.text = "의뢰 선택: %s" % String(contract.get("title", "의뢰"))
	refresh_contract_board()


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

	if target_name == "DispatchDoor":
		call_deferred("go_to_dungeon")


func _on_interactable_interacted(label: String, action: String) -> void:
	if label == "의뢰 게시판":
		status_label.text = "%s: 접수된 현장 의뢰를 확인합니다." % label
		return

	if label == "회사 장부":
		status_label.text = "%s: %s" % [label, GameState.get_company_status_text()]
		return

	status_label.text = "%s: %s" % [label, action]


func _on_game_state_changed() -> void:
	refresh_hud()
	refresh_contract_board()


func refresh_hud() -> void:
	day_value_label.text = str(GameState.day)
	money_value_label.text = str(GameState.money)
	trust_value_label.text = str(GameState.hell_trust)
	reputation_value_label.text = str(GameState.human_reputation)
	hygiene_value_label.text = str(GameState.hygiene)
	risk_value_label.text = str(GameState.illegal_risk)


func go_to_dungeon() -> void:
	if not GameState.has_selected_contract():
		status_label.text = "출동할 의뢰를 먼저 선택하세요."
		open_contract_board()
		return

	close_contract_board()
	get_tree().change_scene_to_file(DUNGEON_TEST_SCENE_PATH)
