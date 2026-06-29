extends Node2D

const UiAssetStyles = preload("res://scripts/UiAssetStyles.gd")
const PlayerBattleTexture = preload("res://assets/sprites/pixellab/주인공/rotations/south.png")
const ExplorerHoldoutTexture = preload("res://assets/sprites/enemies/explorer_holdout.svg")
const HiredInspectorTexture = preload("res://assets/sprites/enemies/hired_inspector.svg")

const DUNGEON_TEST_SCENE_PATH: String = "res://scenes/DungeonTest.tscn"
const BOARD_ORIGIN: Vector2 = Vector2(330, 168)
const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 7
const CELL_SIZE: float = 60.0
const PLAYER_MAX_HP: int = 12
const PLAYER_ATTACK: int = 3
const PLAYER_SKILL_DAMAGE: int = 2
const PLAYER_MOVE_RANGE: int = 3
const PLAYER_SKILL_RANGE: int = 3
const SUPPORT_DEFENSE_REDUCTION: int = 1
const SUPPORT_SKILL_DAMAGE_BONUS: int = 1
const UNIT_SPRITE_SCALE: Vector2 = Vector2(0.66, 0.66)
const INVALID_CELL: Vector2i = Vector2i(-1, -1)
const BOSS_UNIT_ID: String = "boss"
const PHASE_CHOOSE_ACTION: String = "choose_action"
const PHASE_SELECT_MOVE_TILE: String = "select_move_tile"
const PHASE_SELECT_ATTACK_TARGET: String = "select_attack_target"
const PHASE_SELECT_SKILL_TARGET: String = "select_skill_target"
const PHASE_ENEMY_TURN: String = "enemy_turn"
const PHASE_VICTORY: String = "victory"
const PHASE_DEFEAT: String = "defeat"
const ACTION_MOVE: int = 0
const ACTION_ATTACK: int = 1
const ACTION_DEFEND: int = 2
const ACTION_SKILL: int = 3
const ACTION_FLEE: int = 4
const ACTION_WAIT: int = 5
const ACTION_MENU_COLUMNS: int = 2
const ACTION_MENU_ROWS: int = 3

const COLOR_BACKGROUND: Color = Color(0.05, 0.052, 0.061)
const COLOR_TILE_A: Color = Color(0.11, 0.119, 0.137)
const COLOR_TILE_B: Color = Color(0.087, 0.095, 0.112)
const COLOR_TILE_BORDER: Color = Color(0.27, 0.235, 0.165)
const COLOR_PLAYER: Color = Color(0.502, 0.686, 0.408)
const COLOR_ENEMY: Color = Color(0.671, 0.294, 0.271)
const COLOR_MOVE_HIGHLIGHT: Color = Color(0.345, 0.557, 0.769, 0.42)
const COLOR_ATTACK_HIGHLIGHT: Color = Color(0.827, 0.361, 0.294, 0.52)
const COLOR_SKILL_HIGHLIGHT: Color = Color(0.361, 0.784, 0.741, 0.46)
const COLOR_SELECTED_HIGHLIGHT: Color = Color(0.851, 0.694, 0.373, 0.35)
const COLOR_CURSOR_HIGHLIGHT: Color = Color(1.0, 0.894, 0.518, 0.75)
const COLOR_OBSTACLE_TILE: Color = Color(0.19, 0.17, 0.14)
const COLOR_OBJECTIVE_TILE: Color = Color(0.18, 0.32, 0.22)
const COLOR_STAFF_SUPPORT: Color = Color(0.361, 0.549, 0.722)
const COLOR_PANEL: Color = Color(0.078, 0.083, 0.098)
const COLOR_PANEL_DARK: Color = Color(0.047, 0.052, 0.063)
const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)
const COLOR_WARNING: Color = Color(0.808, 0.431, 0.349)
const COLOR_SUCCESS: Color = Color(0.494, 0.686, 0.443)
const OBJECTIVE_CELL: Vector2i = Vector2i(6, 3)
const OBSTACLE_CELLS: Array[Vector2i] = [
	Vector2i(2, 1),
	Vector2i(3, 2),
	Vector2i(4, 3),
	Vector2i(2, 5),
	Vector2i(5, 1),
	Vector2i(6, 5)
]
const STAFF_SUPPORT_UNITS: Array[Dictionary] = [
	{
		"id": "greek_support",
		"label": "그릭",
		"role": "청소반",
		"cell": Vector2i(0, 5),
		"hp": 6,
		"max_hp": 6,
		"attack": 2,
		"move_range": 3,
		"note": "방어 보조"
	},
	{
		"id": "melta_support",
		"label": "멜타",
		"role": "회수반",
		"cell": Vector2i(1, 6),
		"hp": 5,
		"max_hp": 5,
		"attack": 2,
		"move_range": 3,
		"note": "지원 명령 +1"
	}
]

var current_contract: Dictionary = {}
var combat_event: Dictionary = {}
var player_cell: Vector2i = Vector2i(0, 3)
var cursor_cell: Vector2i = player_cell
var selected_unit_id: String = BOSS_UNIT_ID
var player_hp: int = PLAYER_MAX_HP
var staff_units: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var battle_phase: String = PHASE_CHOOSE_ACTION
var has_moved: bool = false
var has_acted: bool = false
var player_defending: bool = false
var skill_used: bool = false
var selected_action_index: int = ACTION_MOVE
var board_layer: Node2D
var highlight_layer: Node2D
var unit_layer: Node2D
var title_label: Label
var objective_label: Label
var hp_label: Label
var result_label: Label
var status_label: Label
var action_log_label: Label
var prompt_label: Label
var action_panel: PanelContainer
var action_detail_label: Label
var target_info_label: Label
var move_button: Button
var attack_button: Button
var defend_button: Button
var skill_button: Button
var flee_button: Button
var wait_button: Button
var retry_button: Button
var return_button: Button
var action_log: Array[String] = []


func _ready() -> void:
	current_contract = GameState.get_selected_contract()
	if current_contract.is_empty():
		current_contract = GameState.get_default_contract()

	combat_event = GameState.get_combat_event(current_contract)
	if combat_event.is_empty():
		combat_event = {
			"title": "현장 전투",
			"label": "방해 세력"
		}

	setup_staff_units()
	setup_enemies()
	build_battle()
	update_units()
	start_player_turn("전투 시작: 행동을 선택하세요.")


func setup_enemies() -> void:
	enemies = [
		{
			"id": "holdout_a",
			"label": "탐사대 잔당",
			"cell": Vector2i(6, 1),
			"hp": 4,
			"max_hp": 4,
			"attack": 2,
			"texture": ExplorerHoldoutTexture
		},
		{
			"id": "holdout_b",
			"label": "고용 검문관",
			"cell": Vector2i(7, 5),
			"hp": 5,
			"max_hp": 5,
			"attack": 2,
			"texture": HiredInspectorTexture
		},
		{
			"id": "holdout_c",
			"label": "잔류 도굴꾼",
			"cell": Vector2i(5, 3),
			"hp": 3,
			"max_hp": 3,
			"attack": 1,
			"texture": ExplorerHoldoutTexture
		}
	]


func setup_staff_units() -> void:
	staff_units.clear()
	for blueprint: Dictionary in STAFF_SUPPORT_UNITS:
		var unit := blueprint.duplicate(true)
		unit["moved"] = false
		unit["acted"] = false
		unit["defending"] = false
		staff_units.append(unit)


func build_battle() -> void:
	create_background()
	create_board()
	create_ui()


func create_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = COLOR_BACKGROUND
	background.position = Vector2.ZERO
	background.size = Vector2(1270, 720)
	add_child(background)


func create_board() -> void:
	board_layer = Node2D.new()
	board_layer.name = "BoardLayer"
	add_child(board_layer)

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var tile := PanelContainer.new()
			tile.name = "Tile_%d_%d" % [x, y]
			tile.position = cell_to_position(Vector2i(x, y))
			tile.size = Vector2(CELL_SIZE, CELL_SIZE)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tile_color := COLOR_TILE_A if (x + y) % 2 == 0 else COLOR_TILE_B
			var cell := Vector2i(x, y)
			if is_obstacle_cell(cell):
				tile_color = COLOR_OBSTACLE_TILE
			elif is_objective_cell(cell):
				tile_color = COLOR_OBJECTIVE_TILE
			tile.add_theme_stylebox_override("panel", make_panel_style(tile_color, COLOR_TILE_BORDER, 1))
			board_layer.add_child(tile)

	highlight_layer = Node2D.new()
	highlight_layer.name = "HighlightLayer"
	add_child(highlight_layer)

	unit_layer = Node2D.new()
	unit_layer.name = "UnitLayer"
	add_child(unit_layer)


func create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)

	var board_input_area := Control.new()
	board_input_area.name = "BoardInputArea"
	board_input_area.offset_left = BOARD_ORIGIN.x
	board_input_area.offset_top = BOARD_ORIGIN.y
	board_input_area.offset_right = BOARD_ORIGIN.x + (float(GRID_WIDTH) * CELL_SIZE)
	board_input_area.offset_bottom = BOARD_ORIGIN.y + (float(GRID_HEIGHT) * CELL_SIZE)
	board_input_area.mouse_filter = Control.MOUSE_FILTER_STOP
	board_input_area.gui_input.connect(_on_board_gui_input)
	canvas.add_child(board_input_area)

	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.offset_left = 24
	panel.offset_top = 20
	panel.offset_right = 760
	panel.offset_bottom = 164
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_TILE_BORDER, 2))
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 1)
	header.add_child(title_box)

	title_label = make_label(String(combat_event.get("title", "현장 전투")), 19, COLOR_GOLD)
	title_box.add_child(title_label)

	var subtitle := make_label(String(current_contract.get("title", "계약 현장")), 12, COLOR_MUTED)
	title_box.add_child(subtitle)

	objective_label = make_label("목표: %s" % get_objective_text(), 13, COLOR_SUCCESS)
	objective_label.custom_minimum_size = Vector2(0.0, 22.0)
	title_box.add_child(objective_label)

	retry_button = Button.new()
	retry_button.text = "재시도"
	retry_button.visible = false
	retry_button.disabled = true
	retry_button.custom_minimum_size = Vector2(104.0, 38.0)
	UiAssetStyles.apply_plate_button_style(retry_button)
	retry_button.pressed.connect(restart_battle)
	header.add_child(retry_button)

	return_button = Button.new()
	return_button.text = "현장 복귀"
	return_button.disabled = true
	return_button.custom_minimum_size = Vector2(126.0, 38.0)
	UiAssetStyles.apply_plate_button_style(return_button)
	return_button.pressed.connect(return_to_dungeon)
	header.add_child(return_button)

	hp_label = make_label("", 15, COLOR_TEXT)
	layout.add_child(hp_label)

	result_label = make_label(get_battle_bonus_text(), 13, COLOR_MUTED)
	result_label.custom_minimum_size = Vector2(0.0, 22.0)
	layout.add_child(result_label)

	action_panel = PanelContainer.new()
	action_panel.name = "ActionPanel"
	action_panel.offset_left = 870
	action_panel.offset_top = 20
	action_panel.offset_right = 1246
	action_panel.offset_bottom = 342
	action_panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_TILE_BORDER, 2))
	canvas.add_child(action_panel)

	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 16)
	action_margin.add_theme_constant_override("margin_top", 14)
	action_margin.add_theme_constant_override("margin_right", 16)
	action_margin.add_theme_constant_override("margin_bottom", 14)
	action_panel.add_child(action_margin)

	var action_layout := VBoxContainer.new()
	action_layout.add_theme_constant_override("separation", 10)
	action_margin.add_child(action_layout)

	var action_title := make_label("전투 명령", 18, COLOR_GOLD)
	action_layout.add_child(action_title)

	action_detail_label = make_label("행동을 선택하세요.", 13, COLOR_MUTED)
	action_detail_label.custom_minimum_size = Vector2(0.0, 44.0)
	action_layout.add_child(action_detail_label)

	var action_grid := GridContainer.new()
	action_grid.columns = 2
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	action_layout.add_child(action_grid)

	move_button = make_action_button("이동", Callable(self, "_on_move_pressed"))
	attack_button = make_action_button("공격", Callable(self, "_on_attack_pressed"))
	defend_button = make_action_button("방어", Callable(self, "_on_defend_pressed"))
	skill_button = make_action_button("지원 명령", Callable(self, "_on_skill_pressed"))
	flee_button = make_action_button("철수", Callable(self, "_on_flee_pressed"))
	wait_button = make_action_button("대기", Callable(self, "_on_wait_pressed"))

	action_grid.add_child(move_button)
	action_grid.add_child(attack_button)
	action_grid.add_child(defend_button)
	action_grid.add_child(skill_button)
	action_grid.add_child(flee_button)
	action_grid.add_child(wait_button)

	target_info_label = make_label("대상 정보 없음", 13, COLOR_MUTED)
	target_info_label.custom_minimum_size = Vector2(0.0, 46.0)
	action_layout.add_child(target_info_label)

	var message_panel := PanelContainer.new()
	message_panel.name = "MessagePanel"
	message_panel.anchor_left = 0.0
	message_panel.anchor_top = 1.0
	message_panel.anchor_right = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.offset_left = 24
	message_panel.offset_top = -124
	message_panel.offset_right = -24
	message_panel.offset_bottom = -20
	message_panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_TILE_BORDER, 2))
	canvas.add_child(message_panel)

	var message_margin := MarginContainer.new()
	message_margin.add_theme_constant_override("margin_left", 18)
	message_margin.add_theme_constant_override("margin_top", 12)
	message_margin.add_theme_constant_override("margin_right", 18)
	message_margin.add_theme_constant_override("margin_bottom", 12)
	message_panel.add_child(message_margin)

	var message_layout := VBoxContainer.new()
	message_layout.add_theme_constant_override("separation", 6)
	message_margin.add_child(message_layout)

	status_label = make_label("", 18, COLOR_TEXT)
	status_label.custom_minimum_size = Vector2(0.0, 28.0)
	action_log_label = make_label("", 14, COLOR_MUTED)
	action_log_label.custom_minimum_size = Vector2(0.0, 26.0)
	prompt_label = make_label("아군 행동", 15, COLOR_GOLD)
	prompt_label.custom_minimum_size = Vector2(0.0, 24.0)
	message_layout.add_child(status_label)
	message_layout.add_child(action_log_label)
	message_layout.add_child(prompt_label)


func make_action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(158.0, 42.0)
	UiAssetStyles.apply_plate_button_style(button)
	button.pressed.connect(callback)
	return button


func update_units() -> void:
	for child in unit_layer.get_children():
		child.queue_free()

	create_objective_marker()
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff):
			create_staff_support_marker(staff)

	create_unit_marker("PlayerUnit", player_cell, PlayerBattleTexture, "사장", player_hp, PLAYER_MAX_HP, COLOR_PLAYER)
	for enemy: Dictionary in enemies:
		var enemy_texture: Texture2D = enemy.get("texture", ExplorerHoldoutTexture)
		create_unit_marker(
			String(enemy.get("id", "Enemy")),
			enemy.get("cell", Vector2i.ZERO),
			enemy_texture,
			String(enemy.get("label", "적")),
			int(enemy.get("hp", 0)),
			int(enemy.get("max_hp", 1)),
			COLOR_ENEMY
		)

	update_hud()
	refresh_highlights()


func create_unit_marker(
	node_name: String,
	cell: Vector2i,
	texture: Texture2D,
	unit_label: String,
	hp: int,
	max_hp: int,
	hp_color: Color
) -> void:
	var marker := Node2D.new()
	marker.name = node_name
	marker.position = cell_to_position(cell)
	unit_layer.add_child(marker)

	var name_label := make_label(unit_label, 10, COLOR_TEXT)
	name_label.position = Vector2(0.0, -13.0)
	name_label.size = Vector2(CELL_SIZE, 14.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(name_label)

	var shadow := ColorRect.new()
	shadow.name = "Shadow"
	shadow.position = Vector2(13.0, CELL_SIZE - 16.0)
	shadow.size = Vector2(CELL_SIZE - 26.0, 6.0)
	shadow.color = Color(0.0, 0.0, 0.0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.43)
	sprite.scale = UNIT_SPRITE_SCALE * 0.92
	marker.add_child(sprite)

	var hp_track := ColorRect.new()
	hp_track.name = "HpTrack"
	hp_track.position = Vector2(7.0, CELL_SIZE - 9.0)
	hp_track.size = Vector2(CELL_SIZE - 14.0, 5.0)
	hp_track.color = COLOR_PANEL_DARK
	hp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_track)

	var hp_fill := ColorRect.new()
	hp_fill.name = "HpFill"
	hp_fill.position = hp_track.position
	var hp_ratio := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	hp_fill.size = Vector2((CELL_SIZE - 14.0) * hp_ratio, 5.0)
	hp_fill.color = hp_color
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_fill)

	var hp_label := make_label("%d/%d" % [hp, max_hp], 9, Color.WHITE)
	hp_label.position = Vector2(7.0, CELL_SIZE - 13.0)
	hp_label.size = Vector2(CELL_SIZE - 14.0, 11.0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_label)


func create_staff_support_marker(support: Dictionary) -> void:
	var cell: Vector2i = support.get("cell", Vector2i.ZERO)
	var marker := Node2D.new()
	marker.name = String(support.get("id", "StaffSupport"))
	marker.position = cell_to_position(cell)
	unit_layer.add_child(marker)

	var plate := PanelContainer.new()
	plate.name = "SupportPlate"
	plate.position = Vector2(8.0, 8.0)
	plate.size = Vector2(CELL_SIZE - 16.0, CELL_SIZE - 16.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", make_panel_style(Color(0.08, 0.13, 0.17, 0.88), COLOR_STAFF_SUPPORT, 2))
	marker.add_child(plate)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 0)
	plate.add_child(layout)

	var name_label := make_label(String(support.get("label", "직원")), 12, COLOR_TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(name_label)

	var role_label := make_label(String(support.get("role", "지원")), 9, COLOR_STAFF_SUPPORT)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(role_label)

	var hp := int(support.get("hp", 0))
	var max_hp := int(support.get("max_hp", 1))
	var hp_label := make_label("%d/%d" % [hp, max_hp], 8, Color.WHITE)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hp_label)


func create_objective_marker() -> void:
	var marker := Node2D.new()
	marker.name = "ObjectiveDevice"
	marker.position = cell_to_position(OBJECTIVE_CELL)
	unit_layer.add_child(marker)

	var device := PanelContainer.new()
	device.name = "DevicePlate"
	device.position = Vector2(10.0, 10.0)
	device.size = Vector2(CELL_SIZE - 20.0, CELL_SIZE - 20.0)
	device.mouse_filter = Control.MOUSE_FILTER_IGNORE
	device.add_theme_stylebox_override("panel", make_panel_style(Color(0.06, 0.12, 0.07, 0.88), COLOR_SUCCESS, 2))
	marker.add_child(device)

	var label := make_label("경보\n장치", 11, COLOR_SUCCESS)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	device.add_child(label)


func refresh_highlights() -> void:
	if highlight_layer == null:
		return

	for child in highlight_layer.get_children():
		child.queue_free()

	if not is_player_control_phase():
		return

	add_cell_highlight(get_selected_unit_cell(), COLOR_SELECTED_HIGHLIGHT, "SelectedCell")
	add_cell_outline(OBJECTIVE_CELL, COLOR_SUCCESS, "ObjectiveCell")

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)
			if cell == get_selected_unit_cell():
				continue

			var enemy_index := get_enemy_index_at_cell(cell)
			if battle_phase == PHASE_SELECT_ATTACK_TARGET:
				if enemy_index != -1 and is_attackable_enemy_cell(cell):
					add_cell_highlight(cell, COLOR_ATTACK_HIGHLIGHT, "AttackCell_%d_%d" % [x, y])
			elif battle_phase == PHASE_SELECT_SKILL_TARGET:
				if enemy_index != -1 and is_skill_target_cell(cell):
					add_cell_highlight(cell, COLOR_SKILL_HIGHLIGHT, "SkillCell_%d_%d" % [x, y])
			elif battle_phase == PHASE_SELECT_MOVE_TILE and is_valid_move_cell(cell):
				add_cell_highlight(cell, COLOR_MOVE_HIGHLIGHT, "MoveCell_%d_%d" % [x, y])

	if battle_phase != PHASE_CHOOSE_ACTION and is_cell_inside(cursor_cell):
		add_cell_outline(cursor_cell, COLOR_CURSOR_HIGHLIGHT, "CursorCell")


func add_cell_highlight(cell: Vector2i, color: Color, node_name: String) -> void:
	var highlight := ColorRect.new()
	highlight.name = node_name
	highlight.position = cell_to_position(cell) + Vector2(4.0, 4.0)
	highlight.size = Vector2(CELL_SIZE - 8.0, CELL_SIZE - 8.0)
	highlight.color = color
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_layer.add_child(highlight)


func add_cell_outline(cell: Vector2i, color: Color, node_name: String) -> void:
	var outline := PanelContainer.new()
	outline.name = node_name
	outline.position = cell_to_position(cell) + Vector2(2.0, 2.0)
	outline.size = Vector2(CELL_SIZE - 4.0, CELL_SIZE - 4.0)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	outline.add_theme_stylebox_override("panel", style)
	highlight_layer.add_child(outline)


func _on_board_gui_input(event: InputEvent) -> void:
	if not is_player_control_phase():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_action_selection()
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var cell := board_local_to_cell(mouse_event.position)
			cursor_cell = cell
			handle_player_cell_action(cell)
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if battle_phase == PHASE_VICTORY:
		if event is InputEventKey:
			var win_key := event as InputEventKey
			if win_key.pressed and not win_key.echo and (win_key.keycode == KEY_ENTER or win_key.keycode == KEY_SPACE):
				return_to_dungeon()
		return

	if battle_phase == PHASE_DEFEAT:
		if event is InputEventKey:
			var lose_key := event as InputEventKey
			if lose_key.pressed and not lose_key.echo and lose_key.keycode == KEY_R:
				restart_battle()
			elif lose_key.pressed and not lose_key.echo and lose_key.keycode == KEY_ESCAPE:
				return_to_dungeon()
		return

	if not is_player_control_phase():
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_action_selection()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var cell := point_to_cell(mouse_event.position)
			handle_player_cell_action(cell)

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			handle_player_key(key_event.keycode)


func handle_player_key(keycode: Key) -> void:
	var offset := key_to_grid_offset(keycode)
	if offset != Vector2i.ZERO:
		if battle_phase == PHASE_CHOOSE_ACTION:
			handle_action_menu_direction(offset)
		else:
			handle_cursor_direction(offset)
		return

	match keycode:
		KEY_ESCAPE:
			cancel_action_selection()
		KEY_E, KEY_SPACE, KEY_ENTER:
			confirm_cursor_action()
		KEY_1:
			execute_action_command(ACTION_MOVE)
		KEY_2:
			execute_action_command(ACTION_ATTACK)
		KEY_3:
			execute_action_command(ACTION_DEFEND)
		KEY_4:
			execute_action_command(ACTION_SKILL)
		KEY_5:
			execute_action_command(ACTION_FLEE)
		KEY_6:
			execute_action_command(ACTION_WAIT)


func key_to_grid_offset(keycode: Key) -> Vector2i:
	match keycode:
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
		KEY_UP, KEY_W:
			return Vector2i.UP
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
	return Vector2i.ZERO


func handle_cursor_direction(offset: Vector2i) -> void:
	if battle_phase == PHASE_SELECT_ATTACK_TARGET or battle_phase == PHASE_SELECT_SKILL_TARGET:
		cycle_target_cursor(offset)
		return

	cursor_cell = clamp_cell_to_board(cursor_cell + offset)
	refresh_highlights()
	update_cursor_status(false)


func handle_action_menu_direction(offset: Vector2i) -> void:
	if battle_phase != PHASE_CHOOSE_ACTION:
		return

	var next_index := get_next_action_index(selected_action_index, offset)
	if next_index == selected_action_index:
		return

	selected_action_index = next_index
	update_action_menu()
	update_status("%s 선택." % get_selected_action_label(), false)


func confirm_cursor_action() -> void:
	match battle_phase:
		PHASE_CHOOSE_ACTION:
			execute_action_command(selected_action_index)
		PHASE_SELECT_MOVE_TILE:
			try_move_to_cell(cursor_cell)
		PHASE_SELECT_ATTACK_TARGET:
			try_attack_cell(cursor_cell)
		PHASE_SELECT_SKILL_TARGET:
			try_skill_cell(cursor_cell)
		_:
			update_status("먼저 행동 메뉴에서 명령을 선택하세요.")


func execute_action_command(action_index: int) -> void:
	selected_action_index = clampi(action_index, 0, get_action_buttons().size() - 1)
	match selected_action_index:
		ACTION_MOVE:
			_on_move_pressed()
		ACTION_ATTACK:
			_on_attack_pressed()
		ACTION_DEFEND:
			_on_defend_pressed()
		ACTION_SKILL:
			_on_skill_pressed()
		ACTION_FLEE:
			_on_flee_pressed()
		ACTION_WAIT:
			_on_wait_pressed()


func select_ally_cell(cell: Vector2i) -> void:
	if cell == player_cell:
		selected_unit_id = BOSS_UNIT_ID
		selected_action_index = ACTION_MOVE
		cursor_cell = player_cell
		refresh_highlights()
		update_status("사장 선택: 직접 전투 지휘.", false)
		update_target_info_label(get_selected_unit_info_text())
		update_action_menu()
		return

	var staff := get_support_at_cell(cell)
	if staff.is_empty():
		return

	selected_unit_id = String(staff.get("id", BOSS_UNIT_ID))
	selected_action_index = ACTION_MOVE
	cursor_cell = cell
	refresh_highlights()
	update_status("%s 선택: 이동/공격 가능." % String(staff.get("label", "직원")), false)
	update_target_info_label(get_selected_unit_info_text())
	update_action_menu()


func handle_player_cell_action(cell: Vector2i) -> void:
	if not is_cell_inside(cell):
		update_status("전투 구역 밖으로는 이동할 수 없습니다.")
		return

	if battle_phase == PHASE_CHOOSE_ACTION and is_ally_cell(cell):
		select_ally_cell(cell)
		return

	match battle_phase:
		PHASE_SELECT_MOVE_TILE:
			try_move_to_cell(cell)
		PHASE_SELECT_ATTACK_TARGET:
			try_attack_cell(cell)
		PHASE_SELECT_SKILL_TARGET:
			try_skill_cell(cell)
		_:
			update_status("먼저 행동 메뉴에서 명령을 선택하세요.")


func _on_move_pressed() -> void:
	selected_action_index = ACTION_MOVE
	if not is_player_control_phase():
		return
	if has_selected_unit_acted():
		update_status("%s은 이번 턴에 이미 행동했습니다." % get_selected_unit_label())
		return
	if has_selected_unit_moved():
		update_status("%s은 이번 턴에 이미 이동했습니다." % get_selected_unit_label())
		return

	enter_move_selection(true)


func _on_attack_pressed() -> void:
	selected_action_index = ACTION_ATTACK
	if not is_player_control_phase():
		return
	if has_selected_unit_acted():
		update_status("%s은 이번 턴에 이미 행동했습니다." % get_selected_unit_label())
		return
	if not has_adjacent_enemy():
		update_status("공격 대상 없음: 기본 공격은 인접한 적에게만 가능합니다.")
		update_target_info_label("공격 대상 없음\n적과 인접한 뒤 다시 선택하세요.")
		return

	enter_attack_selection()


func _on_defend_pressed() -> void:
	selected_action_index = ACTION_DEFEND
	if not is_player_control_phase():
		return
	if has_selected_unit_acted():
		update_status("%s은 이번 턴에 이미 행동했습니다." % get_selected_unit_label())
		return

	set_selected_unit_defending(true)
	set_selected_unit_acted(true)
	update_status("%s 방어 태세: 다음 피해가 감소합니다." % get_selected_unit_label())
	finish_selected_unit_action()


func _on_skill_pressed() -> void:
	selected_action_index = ACTION_SKILL
	if not is_player_control_phase():
		return
	if selected_unit_id != BOSS_UNIT_ID:
		update_status("지원 명령은 사장만 사용할 수 있습니다.")
		return
	if has_selected_unit_acted():
		update_status("%s은 이번 턴에 이미 행동했습니다." % get_selected_unit_label())
		return
	if skill_used:
		update_status("이번 전투에서는 이미 지원 명령을 사용했습니다.")
		return
	if not has_skill_target():
		update_status("지원 명령 대상 없음: 사거리 %d칸 안의 적이 없습니다." % PLAYER_SKILL_RANGE)
		update_target_info_label("지원 명령 대상 없음\n사거리 %d칸 안의 적이 필요합니다." % PLAYER_SKILL_RANGE)
		return

	enter_skill_selection()


func _on_flee_pressed() -> void:
	selected_action_index = ACTION_FLEE
	if not is_player_control_phase():
		return

	update_status("철수: 전투를 해결하지 않고 던전으로 복귀합니다.")
	return_to_dungeon()


func _on_wait_pressed() -> void:
	selected_action_index = ACTION_WAIT
	if not is_player_control_phase():
		return

	set_selected_unit_acted(true)
	update_status("%s 대기." % get_selected_unit_label())
	finish_selected_unit_action()


func enter_move_selection(show_prompt: bool) -> void:
	battle_phase = PHASE_SELECT_MOVE_TILE
	cursor_cell = get_first_move_target_cell()
	if show_prompt:
		update_status("%s 이동할 칸을 선택하세요." % get_selected_unit_label())
	else:
		update_status("이동 선택: WASD로 커서 이동, Enter/Space로 확정.", false)
	refresh_highlights()
	update_action_menu()


func enter_attack_selection() -> void:
	battle_phase = PHASE_SELECT_ATTACK_TARGET
	cursor_cell = get_first_attack_target_cell()
	update_status("공격 대상 선택: WASD로 대상 전환, Enter/Space로 확정.")
	refresh_highlights()
	update_cursor_status(false)
	update_action_menu()


func enter_skill_selection() -> void:
	battle_phase = PHASE_SELECT_SKILL_TARGET
	cursor_cell = get_first_skill_target_cell()
	update_status("지원 명령 대상 선택: WASD로 대상 전환, Enter/Space로 확정.")
	refresh_highlights()
	update_cursor_status(false)
	update_action_menu()


func update_cursor_status(add_to_log: bool) -> void:
	match battle_phase:
		PHASE_SELECT_MOVE_TILE:
			if is_valid_move_cell(cursor_cell):
				update_status("이동 후보: %s. Enter/Space로 확정." % format_cell(cursor_cell), add_to_log)
			else:
				update_status("이동 불가 칸: %s." % format_cell(cursor_cell), add_to_log)
		PHASE_SELECT_ATTACK_TARGET:
			var attack_damage := get_selected_unit_attack()
			if is_attackable_enemy_cell(cursor_cell):
				update_status("공격 대상: %s. Enter/Space로 확정." % get_target_status_text(cursor_cell, attack_damage), add_to_log)
				update_target_info_label(get_target_info_text(cursor_cell, attack_damage, "공격"))
			else:
				update_status("공격 불가 칸: %s." % format_cell(cursor_cell), add_to_log)
				update_target_info_label("공격 불가\n인접한 적만 선택할 수 있습니다.")
		PHASE_SELECT_SKILL_TARGET:
			var skill_damage := get_player_skill_damage()
			if is_skill_target_cell(cursor_cell):
				update_status("지원 명령 대상: %s. Enter/Space로 확정." % get_target_status_text(cursor_cell, skill_damage), add_to_log)
				update_target_info_label(get_target_info_text(cursor_cell, skill_damage, "지원 명령"))
			else:
				update_status("지원 명령 불가 칸: %s." % format_cell(cursor_cell), add_to_log)
				update_target_info_label("지원 명령 불가\n사거리 %d칸 안의 적만 선택할 수 있습니다." % PLAYER_SKILL_RANGE)


func try_move_to_cell(cell: Vector2i) -> void:
	if not is_valid_move_cell(cell):
		if cell == get_selected_unit_cell():
			update_status("이미 서 있는 칸입니다.")
		elif is_obstacle_cell(cell):
			update_status("잔해와 기둥이 막고 있는 칸입니다.")
		elif is_support_cell(cell):
			update_status("지원 직원이 자리 잡은 칸입니다.")
		elif is_objective_cell(cell):
			update_status("경보 장치가 있는 목표 칸입니다.")
		elif is_cell_occupied(cell):
			update_status("이미 점유된 칸입니다.")
		else:
			update_status("이동 범위를 벗어났습니다.")
		return

	set_selected_unit_cell(cell)
	cursor_cell = cell
	set_selected_unit_moved(true)
	battle_phase = PHASE_CHOOSE_ACTION
	update_units()
	update_status("%s 이동 완료. 다음 행동을 선택하세요." % get_selected_unit_label())
	update_action_menu()


func try_attack_cell(cell: Vector2i) -> void:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		update_status("공격할 적을 선택하세요.")
		return
	if not is_attackable_enemy_cell(cell):
		update_status("공격하려면 인접한 적을 선택해야 합니다.")
		return

	set_selected_unit_acted(true)
	player_attack(enemy_index)
	if battle_phase == PHASE_SELECT_ATTACK_TARGET:
		finish_selected_unit_action()


func try_skill_cell(cell: Vector2i) -> void:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		update_status("지원 명령 대상을 선택하세요.")
		return
	if not is_skill_target_cell(cell):
		update_status("지원 명령 사거리를 벗어난 대상입니다.")
		return

	set_selected_unit_acted(true)
	skill_used = true
	player_skill(enemy_index)
	if battle_phase == PHASE_SELECT_SKILL_TARGET:
		finish_selected_unit_action()


func cancel_action_selection() -> void:
	if not is_player_control_phase():
		return
	if battle_phase == PHASE_CHOOSE_ACTION:
		update_status("행동 메뉴에서 명령을 선택하세요.", false)
		return

	battle_phase = PHASE_CHOOSE_ACTION
	cursor_cell = get_selected_unit_cell()
	update_status("선택을 취소했습니다. 행동을 다시 선택하세요.")
	refresh_highlights()
	update_action_menu()


func player_attack(enemy_index: int) -> void:
	var enemy: Dictionary = enemies[enemy_index]
	var attack_damage := get_selected_unit_attack()
	var attacker_label := get_selected_unit_label()
	var next_hp := int(enemy.get("hp", 0)) - attack_damage
	enemy["hp"] = next_hp
	if next_hp <= 0:
		var defeated_label := String(enemy.get("label", "적"))
		enemies.remove_at(enemy_index)
		update_status("%s: %s 제압." % [attacker_label, defeated_label])
	else:
		update_status("%s: %s에게 피해 %d." % [attacker_label, String(enemy.get("label", "적")), attack_damage])

	update_units()
	if enemies.is_empty():
		resolve_victory()


func player_skill(enemy_index: int) -> void:
	var enemy: Dictionary = enemies[enemy_index]
	var skill_damage := get_player_skill_damage()
	var next_hp := int(enemy.get("hp", 0)) - skill_damage
	enemy["hp"] = next_hp
	if next_hp <= 0:
		var defeated_label := String(enemy.get("label", "적"))
		enemies.remove_at(enemy_index)
		update_status("멜타 지원 명령으로 %s 제압." % defeated_label)
	else:
		update_status("멜타 지원 명령: %s에게 피해 %d." % [String(enemy.get("label", "적")), skill_damage])

	update_units()
	if enemies.is_empty():
		resolve_victory()


func start_player_turn(message: String) -> void:
	battle_phase = PHASE_CHOOSE_ACTION
	has_moved = false
	has_acted = false
	player_defending = false
	for index in range(staff_units.size()):
		staff_units[index]["moved"] = false
		staff_units[index]["acted"] = false
		staff_units[index]["defending"] = false
	selected_unit_id = BOSS_UNIT_ID
	selected_action_index = ACTION_MOVE
	cursor_cell = get_selected_unit_cell()
	update_units()
	update_status(message)
	update_action_menu()


func finish_selected_unit_action() -> void:
	if battle_phase == PHASE_VICTORY or battle_phase == PHASE_DEFEAT:
		return
	if all_ally_actions_finished():
		end_player_turn()
		return

	battle_phase = PHASE_CHOOSE_ACTION
	var previous_label := get_selected_unit_label()
	select_next_ready_unit()
	selected_action_index = ACTION_MOVE
	update_units()
	update_status("%s 행동 완료. 다음 아군: %s" % [previous_label, get_selected_unit_label()])
	update_action_menu()


func all_ally_actions_finished() -> bool:
	if not has_acted:
		return false
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff) and not bool(staff.get("acted", false)):
			return false
	return true


func select_next_ready_unit() -> void:
	if not has_acted:
		selected_unit_id = BOSS_UNIT_ID
		cursor_cell = player_cell
		return

	for staff: Dictionary in staff_units:
		if is_staff_alive(staff) and not bool(staff.get("acted", false)):
			selected_unit_id = String(staff.get("id", BOSS_UNIT_ID))
			cursor_cell = staff.get("cell", player_cell)
			return

	selected_unit_id = BOSS_UNIT_ID
	cursor_cell = player_cell


func end_player_turn() -> void:
	if not is_player_control_phase():
		return

	battle_phase = PHASE_ENEMY_TURN
	update_hud()
	update_action_menu()
	refresh_highlights()
	await get_tree().create_timer(0.25).timeout
	await run_enemy_turn()


func run_enemy_turn() -> void:
	var messages: Array[String] = []
	for enemy: Dictionary in enemies:
		var message := ""
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		var target_cell := get_nearest_ally_cell(enemy_cell)
		if target_cell == INVALID_CELL:
			break

		if get_cell_distance(enemy_cell, target_cell) == 1:
			var attack_power := int(enemy.get("attack", 1))
			var target_label := get_ally_label_at_cell(target_cell)
			var reductions: Array[String] = []
			var support_reduction := get_staff_defense_bonus(target_cell)
			if support_reduction > 0:
				attack_power -= support_reduction
				reductions.append("그릭 지원")
			if is_ally_defending(target_cell):
				attack_power -= 1
				reductions.append("방어")
			attack_power = maxi(1, attack_power)
			apply_damage_to_ally(target_cell, attack_power)
			var defense_note := ""
			if not reductions.is_empty():
				defense_note = " (%s)" % " + ".join(reductions)
			message = "%s: %s에게 %d 피해%s" % [
				String(enemy.get("label", "적")),
				target_label,
				attack_power,
				defense_note
			]
		else:
			var before_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
			var next_cell := get_enemy_step_toward_player(enemy)
			enemy["cell"] = next_cell
			if next_cell == before_cell:
				message = "%s: 대기" % String(enemy.get("label", "적"))
			else:
				message = "%s: 접근 (%d,%d)" % [String(enemy.get("label", "적")), next_cell.x + 1, next_cell.y + 1]

		messages.append(message)
		update_units()
		update_status("적 행동: %s" % message, false)
		await get_tree().create_timer(0.28).timeout

		if player_hp <= 0:
			break

	if player_hp <= 0:
		player_hp = 0
		battle_phase = PHASE_DEFEAT
		var failed_objective := get_objective_text()
		update_units()
		return_button.text = "현장 복귀"
		return_button.disabled = false
		retry_button.visible = true
		retry_button.disabled = false
		result_label.text = "목표 실패: %s | 보너스 미적용" % failed_objective
		result_label.add_theme_color_override("font_color", COLOR_WARNING)
		update_status("전투 실패: %s" % failed_objective)
		update_action_menu()
		return

	player_defending = false
	start_player_turn("적 행동: %s" % " / ".join(messages))


func is_player_control_phase() -> bool:
	return battle_phase in [
		PHASE_CHOOSE_ACTION,
		PHASE_SELECT_MOVE_TILE,
		PHASE_SELECT_ATTACK_TARGET,
		PHASE_SELECT_SKILL_TARGET
	]


func is_valid_move_cell(cell: Vector2i) -> bool:
	if not is_cell_inside(cell):
		return false
	if cell == get_selected_unit_cell():
		return false
	if is_cell_occupied(cell):
		return false
	return get_cell_distance(get_selected_unit_cell(), cell) <= get_selected_unit_move_range()


func is_attackable_enemy_cell(cell: Vector2i) -> bool:
	return get_enemy_index_at_cell(cell) != -1 and get_cell_distance(get_selected_unit_cell(), cell) == 1


func is_skill_target_cell(cell: Vector2i) -> bool:
	return selected_unit_id == BOSS_UNIT_ID and get_enemy_index_at_cell(cell) != -1 and get_cell_distance(get_selected_unit_cell(), cell) <= PLAYER_SKILL_RANGE


func has_adjacent_enemy() -> bool:
	for enemy: Dictionary in enemies:
		if get_cell_distance(get_selected_unit_cell(), enemy.get("cell", Vector2i.ZERO)) == 1:
			return true
	return false


func has_skill_target() -> bool:
	if selected_unit_id != BOSS_UNIT_ID:
		return false
	for enemy: Dictionary in enemies:
		if get_cell_distance(get_selected_unit_cell(), enemy.get("cell", Vector2i.ZERO)) <= PLAYER_SKILL_RANGE:
			return true
	return false


func get_first_move_target_cell() -> Vector2i:
	var preferred_offsets: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.UP,
		Vector2i.LEFT,
		Vector2i(2, 0),
		Vector2i(0, 2),
		Vector2i(0, -2),
		Vector2i(-2, 0),
		Vector2i(3, 0),
		Vector2i(0, 3),
		Vector2i(0, -3),
		Vector2i(-3, 0),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	for offset: Vector2i in preferred_offsets:
		var candidate := get_selected_unit_cell() + offset
		if is_valid_move_cell(candidate):
			return candidate
	return get_selected_unit_cell()


func get_first_attack_target_cell() -> Vector2i:
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_attackable_enemy_cell(enemy_cell):
			return enemy_cell
	return get_selected_unit_cell()


func get_first_skill_target_cell() -> Vector2i:
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_skill_target_cell(enemy_cell):
			return enemy_cell
	return get_selected_unit_cell()


func get_attack_target_cells() -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_attackable_enemy_cell(enemy_cell):
			targets.append(enemy_cell)
	return targets


func get_skill_target_cells() -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_skill_target_cell(enemy_cell):
			targets.append(enemy_cell)
	return targets


func get_current_target_cells() -> Array[Vector2i]:
	if battle_phase == PHASE_SELECT_ATTACK_TARGET:
		return get_attack_target_cells()
	if battle_phase == PHASE_SELECT_SKILL_TARGET:
		return get_skill_target_cells()
	var targets: Array[Vector2i] = []
	return targets


func cycle_target_cursor(offset: Vector2i) -> void:
	var targets := get_current_target_cells()
	if targets.is_empty():
		update_cursor_status(false)
		return

	var direction := 1
	if offset.x < 0 or offset.y < 0:
		direction = -1

	var current_index := get_target_index(cursor_cell, targets)
	if current_index == -1:
		current_index = 0
	else:
		current_index = wrapi(current_index + direction, 0, targets.size())

	cursor_cell = targets[current_index]
	refresh_highlights()
	update_cursor_status(false)


func get_target_index(cell: Vector2i, targets: Array[Vector2i]) -> int:
	for index in range(targets.size()):
		if targets[index] == cell:
			return index
	return -1


func get_target_status_text(cell: Vector2i, damage: int) -> String:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		return format_cell(cell)
	var enemy: Dictionary = enemies[enemy_index]
	var enemy_label := String(enemy.get("label", "적"))
	var hp := int(enemy.get("hp", 0))
	var next_hp := maxi(0, hp - damage)
	return "%s HP %d->%d" % [enemy_label, hp, next_hp]


func get_target_info_text(cell: Vector2i, damage: int, action_name: String) -> String:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		return "대상 정보 없음"
	var enemy: Dictionary = enemies[enemy_index]
	var hp := int(enemy.get("hp", 0))
	var max_hp := int(enemy.get("max_hp", 1))
	var next_hp := maxi(0, hp - damage)
	return "%s 대상\n%s HP %d/%d -> %d | 피해 %d" % [
		action_name,
		String(enemy.get("label", "적")),
		hp,
		max_hp,
		next_hp,
		damage
	]


func update_target_info_label(text: String) -> void:
	if target_info_label != null:
		target_info_label.text = text


func get_action_buttons() -> Array[Button]:
	var buttons: Array[Button] = [
		move_button,
		attack_button,
		defend_button,
		skill_button,
		flee_button,
		wait_button
	]
	return buttons


func get_action_label(action_index: int) -> String:
	match action_index:
		ACTION_MOVE:
			return "이동"
		ACTION_ATTACK:
			return "공격"
		ACTION_DEFEND:
			return "방어"
		ACTION_SKILL:
			return "지원 명령"
		ACTION_FLEE:
			return "철수"
		ACTION_WAIT:
			return "대기"
	return "명령"


func get_selected_action_label() -> String:
	return get_action_label(selected_action_index)


func get_action_display_label(action_index: int) -> String:
	var label := get_action_label(action_index)
	if battle_phase == PHASE_SELECT_MOVE_TILE and action_index == ACTION_MOVE:
		label = "이동 선택 중"
	elif battle_phase == PHASE_SELECT_ATTACK_TARGET and action_index == ACTION_ATTACK:
		label = "공격 선택 중"
	elif battle_phase == PHASE_SELECT_SKILL_TARGET and action_index == ACTION_SKILL:
		label = "지원 선택 중"

	if battle_phase == PHASE_CHOOSE_ACTION and action_index == selected_action_index:
		return label
	return label


func is_action_index_enabled(action_index: int) -> bool:
	var buttons := get_action_buttons()
	if action_index < 0 or action_index >= buttons.size():
		return false
	var button := buttons[action_index]
	return button != null and not button.disabled


func normalize_selected_action_index() -> void:
	if battle_phase != PHASE_CHOOSE_ACTION:
		return
	if is_action_index_enabled(selected_action_index):
		return

	var buttons := get_action_buttons()
	for action_index in range(buttons.size()):
		if is_action_index_enabled(action_index):
			selected_action_index = action_index
			return

	selected_action_index = ACTION_MOVE


func get_next_action_index(current_index: int, offset: Vector2i) -> int:
	var direction := Vector2i(signi(offset.x), signi(offset.y))
	if direction == Vector2i.ZERO:
		return current_index

	var candidate := current_index
	while true:
		var row := floori(float(candidate) / float(ACTION_MENU_COLUMNS))
		var column := candidate % ACTION_MENU_COLUMNS

		if direction.x != 0:
			column += direction.x
		else:
			row += direction.y

		if column < 0 or column >= ACTION_MENU_COLUMNS or row < 0 or row >= ACTION_MENU_ROWS:
			return current_index

		candidate = (row * ACTION_MENU_COLUMNS) + column
		if is_action_index_enabled(candidate):
			return candidate

	return current_index


func update_choose_action_info() -> void:
	action_detail_label.text = "%s: %s" % [get_selected_unit_label(), get_selected_action_label()]

	match selected_action_index:
		ACTION_MOVE:
			if has_selected_unit_acted():
				update_target_info_label("이동 불가\n이미 행동했습니다.")
			elif has_selected_unit_moved():
				update_target_info_label("이동 불가\n이미 이동했습니다.")
			else:
				update_target_info_label("이동\n최대 %d칸 이동합니다." % get_selected_unit_move_range())
		ACTION_ATTACK:
			if has_selected_unit_acted():
				update_target_info_label("공격 불가\n이미 행동했습니다.")
			elif has_adjacent_enemy():
				update_target_info_label("공격 가능\n인접한 적이 있습니다.")
			else:
				update_target_info_label("공격 대상 없음\n적과 인접해야 합니다.")
		ACTION_DEFEND:
			if has_selected_unit_acted():
				update_target_info_label("방어 불가\n이미 행동했습니다.")
			else:
				update_target_info_label("방어\n다음 피해를 줄이고 행동을 마칩니다.")
		ACTION_SKILL:
			if selected_unit_id != BOSS_UNIT_ID:
				update_target_info_label("지원 명령 불가\n사장만 사용할 수 있습니다.")
			elif has_selected_unit_acted():
				update_target_info_label("지원 명령 불가\n이미 행동했습니다.")
			elif skill_used:
				update_target_info_label("지원 명령 불가\n이미 사용했습니다.")
			elif has_skill_target():
				update_target_info_label("지원 명령 가능\n사거리 %d칸 안의 적이 있습니다." % PLAYER_SKILL_RANGE)
			else:
				update_target_info_label("지원 명령 대상 없음\n사거리 안의 적이 필요합니다.")
		ACTION_FLEE:
			update_target_info_label("철수\n전투를 해결하지 않고 현장으로 돌아갑니다.")
		ACTION_WAIT:
			update_target_info_label("대기\n행동을 마치고 다음 아군으로 넘깁니다.")


func is_action_button_active(action_index: int) -> bool:
	if battle_phase == PHASE_CHOOSE_ACTION:
		return action_index == selected_action_index
	if battle_phase == PHASE_SELECT_MOVE_TILE:
		return action_index == ACTION_MOVE
	if battle_phase == PHASE_SELECT_ATTACK_TARGET:
		return action_index == ACTION_ATTACK
	if battle_phase == PHASE_SELECT_SKILL_TARGET:
		return action_index == ACTION_SKILL
	return false


func update_action_menu() -> void:
	if move_button == null:
		return

	var can_choose := is_player_control_phase()
	move_button.disabled = not can_choose or has_selected_unit_moved() or has_selected_unit_acted()
	attack_button.disabled = not can_choose or has_selected_unit_acted()
	defend_button.disabled = not can_choose or has_selected_unit_acted()
	skill_button.disabled = not can_choose or selected_unit_id != BOSS_UNIT_ID or has_selected_unit_acted() or skill_used
	flee_button.disabled = not can_choose
	wait_button.disabled = not can_choose

	normalize_selected_action_index()
	var buttons := get_action_buttons()
	for action_index in range(buttons.size()):
		var button := buttons[action_index]
		button.text = get_action_display_label(action_index)
		UiAssetStyles.apply_plate_button_style(button, is_action_button_active(action_index))

	match battle_phase:
		PHASE_CHOOSE_ACTION:
			update_choose_action_info()
			prompt_label.text = "아군 턴: 행동 선택"
		PHASE_SELECT_MOVE_TILE:
			action_detail_label.text = "%s 이동 칸을 선택합니다." % get_selected_unit_label()
			update_target_info_label("이동 선택 중\n장애물, 목표물, 유닛 칸은 이동 불가.")
			prompt_label.text = "아군 턴: 이동 칸 선택"
		PHASE_SELECT_ATTACK_TARGET:
			action_detail_label.text = "빨간 적 대상 중 WASD로 전환, Enter/Space로 확정."
			prompt_label.text = "아군 턴: 공격 대상 선택"
		PHASE_SELECT_SKILL_TARGET:
			action_detail_label.text = "청록 적 대상 중 WASD로 전환, Enter/Space로 확정. 멜타 지원으로 피해가 증가합니다."
			prompt_label.text = "아군 턴: 지원 명령 대상 선택"
		PHASE_ENEMY_TURN:
			action_detail_label.text = "적이 행동 중입니다."
			update_target_info_label("대상 정보 없음")
			prompt_label.text = "적 턴"
		PHASE_VICTORY:
			action_detail_label.text = "전투 승리. 현장 복귀가 가능합니다."
			update_target_info_label("전투 종료\n목표 해결")
			prompt_label.text = "전투 종료"
		PHASE_DEFEAT:
			action_detail_label.text = "전투 실패. 현장 복귀 또는 재시도를 선택하세요."
			update_target_info_label("전투 실패\n재시도 또는 현장 복귀")
			prompt_label.text = "퇴각 또는 재시도"


func get_phase_label() -> String:
	match battle_phase:
		PHASE_CHOOSE_ACTION:
			return "아군 턴: 행동 선택"
		PHASE_SELECT_MOVE_TILE:
			return "아군 턴: 이동 선택"
		PHASE_SELECT_ATTACK_TARGET:
			return "아군 턴: 공격 선택"
		PHASE_SELECT_SKILL_TARGET:
			return "아군 턴: 지원 선택"
		PHASE_ENEMY_TURN:
			return "적 턴"
		PHASE_VICTORY:
			return "승리"
		PHASE_DEFEAT:
			return "패배"
	return "전투"


func get_enemy_step_toward_player(enemy: Dictionary) -> Vector2i:
	var start_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
	var enemy_id := String(enemy.get("id", ""))
	var chase_target := get_nearest_ally_cell(start_cell)
	if chase_target == INVALID_CELL:
		return start_cell

	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {
		start_cell: INVALID_CELL
	}
	var target_cell := INVALID_CELL

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current != start_cell and get_cell_distance(current, chase_target) == 1:
			target_cell = current
			break

		for direction: Vector2i in get_cardinal_directions_toward_target(current, chase_target):
			var next_cell := current + direction
			if not is_cell_inside(next_cell):
				continue
			if came_from.has(next_cell):
				continue
			if is_cell_blocked_for_enemy(next_cell, enemy_id):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)

	if target_cell == INVALID_CELL:
		return start_cell

	var step := target_cell
	while came_from.get(step, INVALID_CELL) != start_cell:
		step = came_from.get(step, start_cell)
	return step


func get_cardinal_directions_toward_target(from_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	var horizontal := signi(target_cell.x - from_cell.x)
	var vertical := signi(target_cell.y - from_cell.y)
	if horizontal != 0:
		directions.append(Vector2i(horizontal, 0))
	if vertical != 0:
		directions.append(Vector2i(0, vertical))

	for fallback: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not directions.has(fallback):
			directions.append(fallback)

	return directions


func is_cell_blocked_for_enemy(cell: Vector2i, moving_enemy_id: String) -> bool:
	if cell == player_cell:
		return true
	if is_obstacle_cell(cell) or is_support_cell(cell) or is_objective_cell(cell):
		return true

	for enemy: Dictionary in enemies:
		if String(enemy.get("id", "")) == moving_enemy_id:
			continue
		if enemy.get("cell", Vector2i.ZERO) == cell:
			return true
	return false


func resolve_victory() -> void:
	battle_phase = PHASE_VICTORY
	var objective := get_objective_text()
	var report := "%s 해결: %s" % [String(combat_event.get("title", "현장 전투")), objective]
	GameState.set_field_battle_resolved(report)
	refresh_highlights()
	retry_button.visible = false
	retry_button.disabled = true
	return_button.text = "현장 복귀"
	return_button.disabled = false
	result_label.text = "%s 적용" % get_battle_bonus_text()
	result_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	update_status("%s | %s" % [report, get_battle_bonus_text()])
	update_action_menu()
	update_hud()


func restart_battle() -> void:
	player_cell = Vector2i(0, 3)
	player_hp = PLAYER_MAX_HP
	selected_unit_id = BOSS_UNIT_ID
	battle_phase = PHASE_CHOOSE_ACTION
	has_moved = false
	has_acted = false
	player_defending = false
	skill_used = false
	action_log.clear()
	setup_staff_units()
	setup_enemies()
	return_button.text = "현장 복귀"
	return_button.disabled = true
	retry_button.visible = false
	retry_button.disabled = true
	result_label.text = get_battle_bonus_text()
	result_label.add_theme_color_override("font_color", COLOR_MUTED)
	update_units()
	start_player_turn("전투 재시작. 행동을 선택하세요.")


func return_to_dungeon() -> void:
	get_tree().change_scene_to_file(DUNGEON_TEST_SCENE_PATH)


func update_status(message: String, add_to_log: bool = true) -> void:
	status_label.text = message
	if add_to_log:
		push_action_log(message)
	update_hud()


func push_action_log(message: String) -> void:
	action_log.append(message)
	while action_log.size() > 4:
		action_log.remove_at(0)

	if action_log_label != null:
		action_log_label.text = " / ".join(action_log)


func update_hud() -> void:
	if hp_label == null:
		return

	var enemy_count := enemies.size()
	var staff_count := get_alive_staff_count()
	var turn_text := get_phase_label()
	hp_label.text = "선택 %s | 보스 HP %d/%d | 직원 %d | 적 %d | %s" % [
		get_selected_unit_label(),
		player_hp,
		PLAYER_MAX_HP,
		staff_count,
		enemy_count,
		turn_text
	]


func get_battle_bonus_text() -> String:
	var bonus: Dictionary = combat_event.get("settlement_bonus", {})
	if bonus.is_empty():
		return "전투 보너스 없음"
	return "전투 보너스: %s" % GameState.format_reward_text(bonus)


func get_objective_text() -> String:
	var objective := String(combat_event.get("objective", "")).strip_edges()
	if objective.is_empty():
		return "방해 세력을 제압하고 현장 작업을 재개하라"
	return objective


func cell_to_position(cell: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE)


func point_to_cell(point: Vector2) -> Vector2i:
	var local := point - BOARD_ORIGIN
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))


func board_local_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))


func clamp_cell_to_board(cell: Vector2i) -> Vector2i:
	return Vector2i(clampi(cell.x, 0, GRID_WIDTH - 1), clampi(cell.y, 0, GRID_HEIGHT - 1))


func format_cell(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x + 1, cell.y + 1]


func is_cell_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT


func is_cell_occupied(cell: Vector2i) -> bool:
	if cell == player_cell:
		return true
	if is_obstacle_cell(cell) or is_support_cell(cell) or is_objective_cell(cell):
		return true
	return get_enemy_index_at_cell(cell) != -1


func is_obstacle_cell(cell: Vector2i) -> bool:
	return OBSTACLE_CELLS.has(cell)


func is_objective_cell(cell: Vector2i) -> bool:
	return cell == OBJECTIVE_CELL


func is_support_cell(cell: Vector2i) -> bool:
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff) and staff.get("cell", Vector2i.ZERO) == cell:
			return true
	return false


func get_support_at_cell(cell: Vector2i) -> Dictionary:
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff) and staff.get("cell", Vector2i.ZERO) == cell:
			return staff
	return {}


func is_ally_cell(cell: Vector2i) -> bool:
	return cell == player_cell or is_support_cell(cell)


func get_nearest_ally_cell(from_cell: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = []
	if player_hp > 0:
		candidates.append(player_cell)
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff):
			candidates.append(staff.get("cell", Vector2i.ZERO))

	if candidates.is_empty():
		return INVALID_CELL

	var best_cell := candidates[0]
	var best_distance := get_cell_distance(from_cell, best_cell)
	for candidate: Vector2i in candidates:
		var distance := get_cell_distance(from_cell, candidate)
		if distance < best_distance:
			best_cell = candidate
			best_distance = distance
	return best_cell


func get_ally_label_at_cell(cell: Vector2i) -> String:
	if cell == player_cell:
		return "사장"
	var staff := get_support_at_cell(cell)
	return String(staff.get("label", "아군"))


func is_ally_defending(cell: Vector2i) -> bool:
	if cell == player_cell:
		return player_defending
	var staff_index := get_staff_index_at_cell(cell)
	if staff_index == -1:
		return false
	return bool(staff_units[staff_index].get("defending", false))


func apply_damage_to_ally(cell: Vector2i, damage: int) -> void:
	if cell == player_cell:
		player_hp = maxi(0, player_hp - damage)
		return

	var staff_index := get_staff_index_at_cell(cell)
	if staff_index != -1:
		var current_hp := int(staff_units[staff_index].get("hp", 0))
		staff_units[staff_index]["hp"] = maxi(0, current_hp - damage)


func get_selected_unit_cell() -> Vector2i:
	if selected_unit_id == BOSS_UNIT_ID:
		return player_cell
	var staff := get_staff_by_id(selected_unit_id)
	return staff.get("cell", player_cell)


func set_selected_unit_cell(cell: Vector2i) -> void:
	if selected_unit_id == BOSS_UNIT_ID:
		player_cell = cell
		return
	var staff_index := get_staff_index_by_id(selected_unit_id)
	if staff_index != -1:
		staff_units[staff_index]["cell"] = cell


func get_selected_unit_label() -> String:
	if selected_unit_id == BOSS_UNIT_ID:
		return "사장"
	var staff := get_staff_by_id(selected_unit_id)
	return String(staff.get("label", "직원"))


func get_selected_unit_attack() -> int:
	if selected_unit_id == BOSS_UNIT_ID:
		return PLAYER_ATTACK
	var staff := get_staff_by_id(selected_unit_id)
	return int(staff.get("attack", 1))


func get_selected_unit_move_range() -> int:
	if selected_unit_id == BOSS_UNIT_ID:
		return PLAYER_MOVE_RANGE
	var staff := get_staff_by_id(selected_unit_id)
	return int(staff.get("move_range", 1))


func has_selected_unit_moved() -> bool:
	if selected_unit_id == BOSS_UNIT_ID:
		return has_moved
	var staff := get_staff_by_id(selected_unit_id)
	return bool(staff.get("moved", false))


func set_selected_unit_moved(value: bool) -> void:
	if selected_unit_id == BOSS_UNIT_ID:
		has_moved = value
		return
	var staff_index := get_staff_index_by_id(selected_unit_id)
	if staff_index != -1:
		staff_units[staff_index]["moved"] = value


func has_selected_unit_acted() -> bool:
	if selected_unit_id == BOSS_UNIT_ID:
		return has_acted
	var staff := get_staff_by_id(selected_unit_id)
	return bool(staff.get("acted", false))


func set_selected_unit_acted(value: bool) -> void:
	if selected_unit_id == BOSS_UNIT_ID:
		has_acted = value
		return
	var staff_index := get_staff_index_by_id(selected_unit_id)
	if staff_index != -1:
		staff_units[staff_index]["acted"] = value


func set_selected_unit_defending(value: bool) -> void:
	if selected_unit_id == BOSS_UNIT_ID:
		player_defending = value
		return
	var staff_index := get_staff_index_by_id(selected_unit_id)
	if staff_index != -1:
		staff_units[staff_index]["defending"] = value


func get_selected_unit_info_text() -> String:
	if selected_unit_id == BOSS_UNIT_ID:
		return "사장\nHP %d/%d | 공격 %d | 이동 %d" % [player_hp, PLAYER_MAX_HP, PLAYER_ATTACK, PLAYER_MOVE_RANGE]
	var staff := get_staff_by_id(selected_unit_id)
	return "%s / %s\nHP %d/%d | 공격 %d | 이동 %d\n%s" % [
		String(staff.get("label", "직원")),
		String(staff.get("role", "지원")),
		int(staff.get("hp", 0)),
		int(staff.get("max_hp", 1)),
		int(staff.get("attack", 1)),
		int(staff.get("move_range", 1)),
		String(staff.get("note", ""))
	]


func get_staff_by_id(staff_id: String) -> Dictionary:
	for staff: Dictionary in staff_units:
		if String(staff.get("id", "")) == staff_id:
			return staff
	return {}


func get_staff_index_by_id(staff_id: String) -> int:
	for index in range(staff_units.size()):
		if String(staff_units[index].get("id", "")) == staff_id:
			return index
	return -1


func get_staff_index_at_cell(cell: Vector2i) -> int:
	for index in range(staff_units.size()):
		if is_staff_alive(staff_units[index]) and staff_units[index].get("cell", Vector2i.ZERO) == cell:
			return index
	return -1


func is_staff_alive(staff: Dictionary) -> bool:
	return int(staff.get("hp", 0)) > 0


func get_alive_staff_count() -> int:
	var count := 0
	for staff: Dictionary in staff_units:
		if is_staff_alive(staff):
			count += 1
	return count


func get_support_summary() -> String:
	var summaries: Array[String] = []
	for support: Dictionary in staff_units:
		if is_staff_alive(support):
			summaries.append("%s: %s" % [String(support.get("label", "직원")), String(support.get("note", "지원"))])
	return " / ".join(summaries)


func get_staff_defense_bonus(target_cell: Vector2i) -> int:
	if target_cell == player_cell and has_support_id("greek_support"):
		return SUPPORT_DEFENSE_REDUCTION
	return 0


func get_player_skill_damage() -> int:
	if has_support_id("melta_support"):
		return PLAYER_SKILL_DAMAGE + SUPPORT_SKILL_DAMAGE_BONUS
	return PLAYER_SKILL_DAMAGE


func has_support_id(support_id: String) -> bool:
	for support: Dictionary in staff_units:
		if is_staff_alive(support) and String(support.get("id", "")) == support_id:
			return true
	return false


func get_enemy_index_at_cell(cell: Vector2i) -> int:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if enemy.get("cell", Vector2i.ZERO) == cell:
			return index
	return -1


func get_cell_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func signi(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


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
