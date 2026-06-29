extends Node2D

const PlayerBattleTexture = preload("res://assets/sprites/pixellab/주인공/rotations/south.png")
const ExplorerHoldoutTexture = preload("res://assets/sprites/enemies/explorer_holdout.svg")
const HiredInspectorTexture = preload("res://assets/sprites/enemies/hired_inspector.svg")

const DUNGEON_TEST_SCENE_PATH: String = "res://scenes/DungeonTest.tscn"
const BOARD_ORIGIN: Vector2 = Vector2(407, 142)
const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 6
const CELL_SIZE: float = 68.0
const PLAYER_MAX_HP: int = 12
const PLAYER_ATTACK: int = 3
const PLAYER_SKILL_DAMAGE: int = 2
const PLAYER_MOVE_RANGE: int = 2
const PLAYER_SKILL_RANGE: int = 2
const UNIT_SPRITE_SCALE: Vector2 = Vector2(0.66, 0.66)
const PHASE_CHOOSE_ACTION: String = "choose_action"
const PHASE_SELECT_MOVE_TILE: String = "select_move_tile"
const PHASE_SELECT_ATTACK_TARGET: String = "select_attack_target"
const PHASE_SELECT_SKILL_TARGET: String = "select_skill_target"
const PHASE_ENEMY_TURN: String = "enemy_turn"
const PHASE_VICTORY: String = "victory"
const PHASE_DEFEAT: String = "defeat"

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
const COLOR_PANEL: Color = Color(0.078, 0.083, 0.098)
const COLOR_PANEL_DARK: Color = Color(0.047, 0.052, 0.063)
const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)
const COLOR_WARNING: Color = Color(0.808, 0.431, 0.349)
const COLOR_SUCCESS: Color = Color(0.494, 0.686, 0.443)

var current_contract: Dictionary = {}
var combat_event: Dictionary = {}
var player_cell: Vector2i = Vector2i(0, 2)
var cursor_cell: Vector2i = player_cell
var player_hp: int = PLAYER_MAX_HP
var enemies: Array[Dictionary] = []
var battle_phase: String = PHASE_CHOOSE_ACTION
var has_moved: bool = false
var has_acted: bool = false
var player_defending: bool = false
var skill_used: bool = false
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

	setup_enemies()
	build_battle()
	update_units()
	start_player_turn("전투 시작: 행동을 선택하세요.")


func setup_enemies() -> void:
	enemies = [
		{
			"id": "holdout_a",
			"label": "탐사대 잔당",
			"cell": Vector2i(4, 1),
			"hp": 4,
			"max_hp": 4,
			"attack": 2,
			"texture": ExplorerHoldoutTexture
		},
		{
			"id": "holdout_b",
			"label": "고용 검문관",
			"cell": Vector2i(5, 4),
			"hp": 5,
			"max_hp": 5,
			"attack": 2,
			"texture": HiredInspectorTexture
		}
	]


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
	panel.offset_bottom = 174
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
	retry_button.custom_minimum_size = Vector2(86.0, 34.0)
	retry_button.pressed.connect(restart_battle)
	header.add_child(retry_button)

	return_button = Button.new()
	return_button.text = "현장 복귀"
	return_button.disabled = true
	return_button.custom_minimum_size = Vector2(110.0, 34.0)
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
	skill_button = make_action_button("스킬", Callable(self, "_on_skill_pressed"))
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
	message_panel.offset_top = -132
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
	button.custom_minimum_size = Vector2(158.0, 38.0)
	button.pressed.connect(callback)
	return button


func update_units() -> void:
	for child in unit_layer.get_children():
		child.queue_free()

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
	shadow.position = Vector2(15.0, 51.0)
	shadow.size = Vector2(38.0, 7.0)
	shadow.color = Color(0.0, 0.0, 0.0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.43)
	sprite.scale = UNIT_SPRITE_SCALE
	marker.add_child(sprite)

	var hp_track := ColorRect.new()
	hp_track.name = "HpTrack"
	hp_track.position = Vector2(8.0, 58.0)
	hp_track.size = Vector2(52.0, 6.0)
	hp_track.color = COLOR_PANEL_DARK
	hp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_track)

	var hp_fill := ColorRect.new()
	hp_fill.name = "HpFill"
	hp_fill.position = hp_track.position
	var hp_ratio := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	hp_fill.size = Vector2(52.0 * hp_ratio, 6.0)
	hp_fill.color = hp_color
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_fill)

	var hp_label := make_label("%d/%d" % [hp, max_hp], 9, Color.WHITE)
	hp_label.position = Vector2(8.0, 55.0)
	hp_label.size = Vector2(52.0, 12.0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(hp_label)


func refresh_highlights() -> void:
	if highlight_layer == null:
		return

	for child in highlight_layer.get_children():
		child.queue_free()

	if not is_player_control_phase():
		return

	add_cell_highlight(player_cell, COLOR_SELECTED_HIGHLIGHT, "SelectedCell")

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)
			if cell == player_cell:
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
		handle_cursor_direction(offset)
		return

	match keycode:
		KEY_ESCAPE:
			cancel_action_selection()
		KEY_SPACE, KEY_ENTER:
			confirm_cursor_action()
		KEY_1:
			_on_move_pressed()
		KEY_2:
			_on_attack_pressed()
		KEY_3:
			_on_defend_pressed()
		KEY_4:
			_on_skill_pressed()
		KEY_5:
			_on_flee_pressed()
		KEY_6:
			_on_wait_pressed()


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
	if battle_phase == PHASE_CHOOSE_ACTION:
		if has_moved:
			update_status("이번 턴에는 이미 이동했습니다.")
			return
		enter_move_selection(false)

	if battle_phase == PHASE_SELECT_ATTACK_TARGET or battle_phase == PHASE_SELECT_SKILL_TARGET:
		cycle_target_cursor(offset)
		return

	cursor_cell = clamp_cell_to_board(cursor_cell + offset)
	refresh_highlights()
	update_cursor_status(false)


func confirm_cursor_action() -> void:
	match battle_phase:
		PHASE_SELECT_MOVE_TILE:
			try_move_to_cell(cursor_cell)
		PHASE_SELECT_ATTACK_TARGET:
			try_attack_cell(cursor_cell)
		PHASE_SELECT_SKILL_TARGET:
			try_skill_cell(cursor_cell)
		_:
			update_status("먼저 행동 메뉴에서 명령을 선택하세요.")


func handle_player_cell_action(cell: Vector2i) -> void:
	if not is_cell_inside(cell):
		update_status("전투 구역 밖으로는 이동할 수 없습니다.")
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
	if not is_player_control_phase():
		return
	if has_moved:
		update_status("이번 턴에는 이미 이동했습니다.")
		return

	enter_move_selection(true)


func _on_attack_pressed() -> void:
	if not is_player_control_phase():
		return
	if has_acted:
		update_status("이번 턴에는 이미 행동했습니다.")
		return
	if not has_adjacent_enemy():
		update_status("공격 대상 없음: 기본 공격은 인접한 적에게만 가능합니다.")
		update_target_info_label("공격 대상 없음\n적과 인접한 뒤 다시 선택하세요.")
		return

	enter_attack_selection()


func _on_defend_pressed() -> void:
	if not is_player_control_phase():
		return
	if has_acted:
		update_status("이번 턴에는 이미 행동했습니다.")
		return

	player_defending = true
	has_acted = true
	update_status("방어 태세: 다음 피해가 감소합니다.")
	end_player_turn()


func _on_skill_pressed() -> void:
	if not is_player_control_phase():
		return
	if has_acted:
		update_status("이번 턴에는 이미 행동했습니다.")
		return
	if skill_used:
		update_status("이번 전투에서는 이미 스킬을 사용했습니다.")
		return
	if not has_skill_target():
		update_status("스킬 대상 없음: 사거리 %d칸 안의 적이 없습니다." % PLAYER_SKILL_RANGE)
		update_target_info_label("스킬 대상 없음\n사거리 %d칸 안의 적이 필요합니다." % PLAYER_SKILL_RANGE)
		return

	enter_skill_selection()


func _on_flee_pressed() -> void:
	if not is_player_control_phase():
		return

	update_status("철수: 전투를 해결하지 않고 던전으로 복귀합니다.")
	return_to_dungeon()


func _on_wait_pressed() -> void:
	if not is_player_control_phase():
		return

	has_acted = true
	update_status("대기: 턴을 넘깁니다.")
	end_player_turn()


func enter_move_selection(show_prompt: bool) -> void:
	battle_phase = PHASE_SELECT_MOVE_TILE
	cursor_cell = get_first_move_target_cell()
	if show_prompt:
		update_status("이동할 칸을 선택하세요. 클릭하거나 WASD로 커서 이동 후 Enter/Space로 확정.")
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
	update_status("스킬 대상 선택: WASD로 대상 전환, Enter/Space로 확정.")
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
			if is_attackable_enemy_cell(cursor_cell):
				update_status("공격 대상: %s. Enter/Space로 확정." % get_target_status_text(cursor_cell, PLAYER_ATTACK), add_to_log)
				update_target_info_label(get_target_info_text(cursor_cell, PLAYER_ATTACK, "공격"))
			else:
				update_status("공격 불가 칸: %s." % format_cell(cursor_cell), add_to_log)
				update_target_info_label("공격 불가\n인접한 적만 선택할 수 있습니다.")
		PHASE_SELECT_SKILL_TARGET:
			if is_skill_target_cell(cursor_cell):
				update_status("스킬 대상: %s. Enter/Space로 확정." % get_target_status_text(cursor_cell, PLAYER_SKILL_DAMAGE), add_to_log)
				update_target_info_label(get_target_info_text(cursor_cell, PLAYER_SKILL_DAMAGE, "스킬"))
			else:
				update_status("스킬 불가 칸: %s." % format_cell(cursor_cell), add_to_log)
				update_target_info_label("스킬 불가\n사거리 %d칸 안의 적만 선택할 수 있습니다." % PLAYER_SKILL_RANGE)


func try_move_to_cell(cell: Vector2i) -> void:
	if not is_valid_move_cell(cell):
		if cell == player_cell:
			update_status("이미 서 있는 칸입니다.")
		elif is_cell_occupied(cell):
			update_status("이미 점유된 칸입니다.")
		else:
			update_status("이동 범위를 벗어났습니다.")
		return

	player_cell = cell
	cursor_cell = player_cell
	has_moved = true
	battle_phase = PHASE_CHOOSE_ACTION
	update_units()
	update_status("보스를 이동했습니다. 다음 행동을 선택하세요.")
	update_action_menu()


func try_attack_cell(cell: Vector2i) -> void:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		update_status("공격할 적을 선택하세요.")
		return
	if not is_attackable_enemy_cell(cell):
		update_status("공격하려면 인접한 적을 선택해야 합니다.")
		return

	has_acted = true
	player_attack(enemy_index)
	if battle_phase == PHASE_SELECT_ATTACK_TARGET:
		end_player_turn()


func try_skill_cell(cell: Vector2i) -> void:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index == -1:
		update_status("스킬 대상을 선택하세요.")
		return
	if not is_skill_target_cell(cell):
		update_status("스킬 사거리를 벗어난 대상입니다.")
		return

	has_acted = true
	skill_used = true
	player_skill(enemy_index)
	if battle_phase == PHASE_SELECT_SKILL_TARGET:
		end_player_turn()


func cancel_action_selection() -> void:
	if not is_player_control_phase():
		return
	if battle_phase == PHASE_CHOOSE_ACTION:
		update_status("행동 메뉴에서 명령을 선택하세요.", false)
		return

	battle_phase = PHASE_CHOOSE_ACTION
	cursor_cell = player_cell
	update_status("선택을 취소했습니다. 행동을 다시 선택하세요.")
	refresh_highlights()
	update_action_menu()


func player_attack(enemy_index: int) -> void:
	var enemy: Dictionary = enemies[enemy_index]
	var next_hp := int(enemy.get("hp", 0)) - PLAYER_ATTACK
	enemy["hp"] = next_hp
	if next_hp <= 0:
		var defeated_label := String(enemy.get("label", "적"))
		enemies.remove_at(enemy_index)
		update_status("%s 제압." % defeated_label)
	else:
		update_status("%s에게 피해 %d." % [String(enemy.get("label", "적")), PLAYER_ATTACK])

	update_units()
	if enemies.is_empty():
		resolve_victory()


func player_skill(enemy_index: int) -> void:
	var enemy: Dictionary = enemies[enemy_index]
	var next_hp := int(enemy.get("hp", 0)) - PLAYER_SKILL_DAMAGE
	enemy["hp"] = next_hp
	if next_hp <= 0:
		var defeated_label := String(enemy.get("label", "적"))
		enemies.remove_at(enemy_index)
		update_status("현장 명령으로 %s 제압." % defeated_label)
	else:
		update_status("현장 명령: %s에게 피해 %d." % [String(enemy.get("label", "적")), PLAYER_SKILL_DAMAGE])

	update_units()
	if enemies.is_empty():
		resolve_victory()


func start_player_turn(message: String) -> void:
	battle_phase = PHASE_CHOOSE_ACTION
	has_moved = false
	has_acted = false
	player_defending = false
	cursor_cell = player_cell
	update_units()
	update_status(message)
	update_action_menu()


func end_player_turn() -> void:
	if not is_player_control_phase():
		return

	battle_phase = PHASE_ENEMY_TURN
	update_hud()
	update_action_menu()
	refresh_highlights()
	await get_tree().create_timer(0.25).timeout
	run_enemy_turn()


func run_enemy_turn() -> void:
	var messages: Array[String] = []
	for enemy: Dictionary in enemies:
		if get_cell_distance(enemy.get("cell", Vector2i.ZERO), player_cell) == 1:
			var attack_power := int(enemy.get("attack", 1))
			if player_defending:
				attack_power = maxi(1, attack_power - 1)
			player_hp -= attack_power
			var defense_note := " (방어)" if player_defending else ""
			messages.append("%s: 보스에게 %d 피해%s" % [String(enemy.get("label", "적")), attack_power, defense_note])
		else:
			var before_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
			var next_cell := get_enemy_step_toward_player(enemy)
			enemy["cell"] = next_cell
			if next_cell == before_cell:
				messages.append("%s: 대기" % String(enemy.get("label", "적")))
			else:
				messages.append("%s: 접근 (%d,%d)" % [String(enemy.get("label", "적")), next_cell.x + 1, next_cell.y + 1])

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
	if cell == player_cell:
		return false
	if is_cell_occupied(cell):
		return false
	return get_cell_distance(player_cell, cell) <= PLAYER_MOVE_RANGE


func is_attackable_enemy_cell(cell: Vector2i) -> bool:
	return get_enemy_index_at_cell(cell) != -1 and get_cell_distance(player_cell, cell) == 1


func is_skill_target_cell(cell: Vector2i) -> bool:
	return get_enemy_index_at_cell(cell) != -1 and get_cell_distance(player_cell, cell) <= PLAYER_SKILL_RANGE


func has_adjacent_enemy() -> bool:
	for enemy: Dictionary in enemies:
		if get_cell_distance(player_cell, enemy.get("cell", Vector2i.ZERO)) == 1:
			return true
	return false


func has_skill_target() -> bool:
	for enemy: Dictionary in enemies:
		if get_cell_distance(player_cell, enemy.get("cell", Vector2i.ZERO)) <= PLAYER_SKILL_RANGE:
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
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	for offset: Vector2i in preferred_offsets:
		var candidate := player_cell + offset
		if is_valid_move_cell(candidate):
			return candidate
	return player_cell


func get_first_attack_target_cell() -> Vector2i:
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_attackable_enemy_cell(enemy_cell):
			return enemy_cell
	return player_cell


func get_first_skill_target_cell() -> Vector2i:
	for enemy: Dictionary in enemies:
		var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
		if is_skill_target_cell(enemy_cell):
			return enemy_cell
	return player_cell


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


func update_action_menu() -> void:
	if move_button == null:
		return

	var can_choose := is_player_control_phase()
	move_button.disabled = not can_choose or has_moved
	attack_button.disabled = not can_choose or has_acted
	defend_button.disabled = not can_choose or has_acted
	skill_button.disabled = not can_choose or has_acted or skill_used
	flee_button.disabled = not can_choose
	wait_button.disabled = not can_choose

	move_button.text = "이동 선택 중" if battle_phase == PHASE_SELECT_MOVE_TILE else "이동"
	attack_button.text = "공격 선택 중" if battle_phase == PHASE_SELECT_ATTACK_TARGET else "공격"
	skill_button.text = "스킬 선택 중" if battle_phase == PHASE_SELECT_SKILL_TARGET else "스킬"
	defend_button.text = "방어"
	flee_button.text = "철수"
	wait_button.text = "대기"

	match battle_phase:
		PHASE_CHOOSE_ACTION:
			action_detail_label.text = "명령을 선택하세요. 이동 후에도 행동을 한 번 더 고를 수 있습니다."
			if has_adjacent_enemy():
				update_target_info_label("공격 가능\n인접한 적이 있습니다.")
			elif has_skill_target() and not skill_used:
				update_target_info_label("스킬 가능\n사거리 %d칸 안의 적이 있습니다." % PLAYER_SKILL_RANGE)
			else:
				update_target_info_label("대상 정보 없음\n공격은 인접, 스킬은 %d칸 사거리입니다." % PLAYER_SKILL_RANGE)
			prompt_label.text = "아군 턴: 행동 선택"
		PHASE_SELECT_MOVE_TILE:
			action_detail_label.text = "파란 칸을 클릭하거나 WASD로 커서 이동 후 Enter/Space로 확정."
			update_target_info_label("이동 선택 중\n파란 칸만 이동할 수 있습니다.")
			prompt_label.text = "아군 턴: 이동 칸 선택"
		PHASE_SELECT_ATTACK_TARGET:
			action_detail_label.text = "빨간 적 대상 중 WASD로 전환, Enter/Space로 확정."
			prompt_label.text = "아군 턴: 공격 대상 선택"
		PHASE_SELECT_SKILL_TARGET:
			action_detail_label.text = "청록 적 대상 중 WASD로 전환, Enter/Space로 확정. 전투당 1회."
			prompt_label.text = "아군 턴: 스킬 대상 선택"
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
			return "아군 턴: 스킬 선택"
		PHASE_ENEMY_TURN:
			return "적 턴"
		PHASE_VICTORY:
			return "승리"
		PHASE_DEFEAT:
			return "패배"
	return "전투"


func get_enemy_step_toward_player(enemy: Dictionary) -> Vector2i:
	var enemy_cell: Vector2i = enemy.get("cell", Vector2i.ZERO)
	var enemy_id := String(enemy.get("id", ""))
	var candidates: Array[Vector2i] = []

	if player_cell.x != enemy_cell.x:
		candidates.append(enemy_cell + Vector2i(signi(player_cell.x - enemy_cell.x), 0))
	if player_cell.y != enemy_cell.y:
		candidates.append(enemy_cell + Vector2i(0, signi(player_cell.y - enemy_cell.y)))

	for candidate: Vector2i in candidates:
		if is_cell_inside(candidate) and not is_cell_blocked_for_enemy(candidate, enemy_id):
			return candidate

	return enemy_cell


func is_cell_blocked_for_enemy(cell: Vector2i, moving_enemy_id: String) -> bool:
	if cell == player_cell:
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
	player_cell = Vector2i(0, 2)
	player_hp = PLAYER_MAX_HP
	battle_phase = PHASE_CHOOSE_ACTION
	has_moved = false
	has_acted = false
	player_defending = false
	skill_used = false
	action_log.clear()
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
	var turn_text := get_phase_label()
	hp_label.text = "보스 HP %d/%d | 적 %d | %s" % [player_hp, PLAYER_MAX_HP, enemy_count, turn_text]


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
	return get_enemy_index_at_cell(cell) != -1


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
