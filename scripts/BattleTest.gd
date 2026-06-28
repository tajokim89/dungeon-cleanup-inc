extends Node2D

const DUNGEON_TEST_SCENE_PATH: String = "res://scenes/DungeonTest.tscn"
const BOARD_ORIGIN: Vector2 = Vector2(407, 142)
const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 6
const CELL_SIZE: float = 68.0
const PLAYER_MAX_HP: int = 12
const PLAYER_ATTACK: int = 3
const PLAYER_MOVE_RANGE: int = 2

const COLOR_BACKGROUND: Color = Color(0.05, 0.052, 0.061)
const COLOR_TILE_A: Color = Color(0.11, 0.119, 0.137)
const COLOR_TILE_B: Color = Color(0.087, 0.095, 0.112)
const COLOR_TILE_BORDER: Color = Color(0.27, 0.235, 0.165)
const COLOR_PLAYER: Color = Color(0.502, 0.686, 0.408)
const COLOR_ENEMY: Color = Color(0.671, 0.294, 0.271)
const COLOR_MOVE_HIGHLIGHT: Color = Color(0.345, 0.557, 0.769, 0.42)
const COLOR_ATTACK_HIGHLIGHT: Color = Color(0.827, 0.361, 0.294, 0.52)
const COLOR_SELECTED_HIGHLIGHT: Color = Color(0.851, 0.694, 0.373, 0.35)
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
var player_hp: int = PLAYER_MAX_HP
var enemies: Array[Dictionary] = []
var turn_state: String = "player"
var board_layer: Node2D
var highlight_layer: Node2D
var unit_layer: Node2D
var title_label: Label
var hp_label: Label
var result_label: Label
var status_label: Label
var action_log_label: Label
var prompt_label: Label
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
	update_status("전투 시작: 이동하거나 인접한 적을 공격하세요.")


func setup_enemies() -> void:
	enemies = [
		{
			"id": "holdout_a",
			"label": "탐사대 잔당",
			"cell": Vector2i(4, 1),
			"hp": 4,
			"attack": 2
		},
		{
			"id": "holdout_b",
			"label": "고용 검문관",
			"cell": Vector2i(5, 4),
			"hp": 5,
			"attack": 2
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


func update_units() -> void:
	for child in unit_layer.get_children():
		child.queue_free()

	create_unit_marker("PlayerUnit", player_cell, COLOR_PLAYER, "사장\nHP %d" % player_hp)
	for enemy: Dictionary in enemies:
		create_unit_marker(
			String(enemy.get("id", "Enemy")),
			enemy.get("cell", Vector2i.ZERO),
			COLOR_ENEMY,
			"%s\nHP %d" % [String(enemy.get("label", "적")), int(enemy.get("hp", 0))]
		)

	update_hud()
	refresh_highlights()


func create_unit_marker(node_name: String, cell: Vector2i, color: Color, text: String) -> void:
	var marker := PanelContainer.new()
	marker.name = node_name
	marker.position = cell_to_position(cell) + Vector2(7.0, 7.0)
	marker.size = Vector2(CELL_SIZE - 14.0, CELL_SIZE - 14.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_stylebox_override("panel", make_panel_style(color, Color.WHITE, 1))
	unit_layer.add_child(marker)

	var label := make_label(text, 13, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(label)


func refresh_highlights() -> void:
	if highlight_layer == null:
		return

	for child in highlight_layer.get_children():
		child.queue_free()

	if turn_state != "player":
		return

	add_cell_highlight(player_cell, COLOR_SELECTED_HIGHLIGHT, "SelectedCell")

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell := Vector2i(x, y)
			if cell == player_cell:
				continue

			if get_enemy_index_at_cell(cell) != -1:
				if get_cell_distance(player_cell, cell) == 1:
					add_cell_highlight(cell, COLOR_ATTACK_HIGHLIGHT, "AttackCell_%d_%d" % [x, y])
				continue

			if get_cell_distance(player_cell, cell) <= PLAYER_MOVE_RANGE and not is_cell_occupied(cell):
				add_cell_highlight(cell, COLOR_MOVE_HIGHLIGHT, "MoveCell_%d_%d" % [x, y])


func add_cell_highlight(cell: Vector2i, color: Color, node_name: String) -> void:
	var highlight := ColorRect.new()
	highlight.name = node_name
	highlight.position = cell_to_position(cell) + Vector2(4.0, 4.0)
	highlight.size = Vector2(CELL_SIZE - 8.0, CELL_SIZE - 8.0)
	highlight.color = color
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_layer.add_child(highlight)


func _unhandled_input(event: InputEvent) -> void:
	if turn_state == "won":
		if event is InputEventKey:
			var win_key := event as InputEventKey
			if win_key.pressed and not win_key.echo and (win_key.keycode == KEY_ENTER or win_key.keycode == KEY_SPACE):
				return_to_dungeon()
		return

	if turn_state == "lost":
		if event is InputEventKey:
			var lose_key := event as InputEventKey
			if lose_key.pressed and not lose_key.echo and lose_key.keycode == KEY_R:
				restart_battle()
			elif lose_key.pressed and not lose_key.echo and lose_key.keycode == KEY_ESCAPE:
				return_to_dungeon()
		return

	if turn_state != "player":
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var cell := point_to_cell(mouse_event.position)
			if is_cell_inside(cell):
				handle_player_cell_action(cell)

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			handle_player_key(key_event.keycode)


func handle_player_key(keycode: Key) -> void:
	var offset := Vector2i.ZERO
	match keycode:
		KEY_LEFT, KEY_A:
			offset = Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			offset = Vector2i.RIGHT
		KEY_UP, KEY_W:
			offset = Vector2i.UP
		KEY_DOWN, KEY_S:
			offset = Vector2i.DOWN
		KEY_SPACE, KEY_ENTER:
			attack_first_adjacent_enemy()
			return

	if offset != Vector2i.ZERO:
		handle_player_cell_action(player_cell + offset)


func handle_player_cell_action(cell: Vector2i) -> void:
	var enemy_index := get_enemy_index_at_cell(cell)
	if enemy_index != -1:
		if get_cell_distance(player_cell, cell) == 1:
			player_attack(enemy_index)
			if turn_state == "player":
				end_player_turn()
		else:
			update_status("공격하려면 인접해야 합니다.")
		return

	if get_cell_distance(player_cell, cell) > PLAYER_MOVE_RANGE:
		update_status("이동 범위를 벗어났습니다.")
		return

	if is_cell_occupied(cell):
		update_status("이미 점유된 칸입니다.")
		return

	player_cell = cell
	update_status("보스를 이동했습니다.")
	update_units()
	end_player_turn()


func attack_first_adjacent_enemy() -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if get_cell_distance(player_cell, enemy.get("cell", Vector2i.ZERO)) == 1:
			player_attack(index)
			if turn_state == "player":
				end_player_turn()
			return

	update_status("인접한 적이 없습니다.")


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


func end_player_turn() -> void:
	if turn_state != "player":
		return

	turn_state = "enemy"
	update_hud()
	refresh_highlights()
	await get_tree().create_timer(0.25).timeout
	run_enemy_turn()


func run_enemy_turn() -> void:
	var messages: Array[String] = []
	for enemy: Dictionary in enemies:
		if get_cell_distance(enemy.get("cell", Vector2i.ZERO), player_cell) == 1:
			var attack_power := int(enemy.get("attack", 1))
			player_hp -= attack_power
			messages.append("%s: 보스에게 %d 피해" % [String(enemy.get("label", "적")), attack_power])
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
		turn_state = "lost"
		update_units()
		return_button.text = "현장 복귀"
		return_button.disabled = false
		retry_button.visible = true
		retry_button.disabled = false
		result_label.text = "전투 실패: 보너스 미적용"
		result_label.add_theme_color_override("font_color", COLOR_WARNING)
		update_status("전투 실패")
		prompt_label.text = "퇴각 또는 재시도"
		return

	turn_state = "player"
	update_units()
	update_status("적 행동: %s" % " / ".join(messages))


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
	turn_state = "won"
	var report := "%s 해결: 방해 세력을 제압했습니다." % String(combat_event.get("title", "현장 전투"))
	GameState.set_field_battle_resolved(report)
	refresh_highlights()
	retry_button.visible = false
	retry_button.disabled = true
	return_button.text = "현장 복귀"
	return_button.disabled = false
	result_label.text = "%s 적용" % get_battle_bonus_text()
	result_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	prompt_label.text = "전투 종료"
	update_status("%s | %s" % [report, get_battle_bonus_text()])
	update_hud()


func restart_battle() -> void:
	player_cell = Vector2i(0, 2)
	player_hp = PLAYER_MAX_HP
	turn_state = "player"
	action_log.clear()
	setup_enemies()
	return_button.text = "현장 복귀"
	return_button.disabled = true
	retry_button.visible = false
	retry_button.disabled = true
	result_label.text = get_battle_bonus_text()
	result_label.add_theme_color_override("font_color", COLOR_MUTED)
	update_units()
	prompt_label.text = "아군 행동"
	update_status("전투 재시작.")


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
	var turn_text := "아군 턴"
	if turn_state == "enemy":
		turn_text = "적 턴"
	elif turn_state == "won":
		turn_text = "승리"
	elif turn_state == "lost":
		turn_text = "패배"

	hp_label.text = "보스 HP %d/%d | 적 %d | %s" % [player_hp, PLAYER_MAX_HP, enemy_count, turn_text]


func get_battle_bonus_text() -> String:
	var bonus: Dictionary = combat_event.get("settlement_bonus", {})
	if bonus.is_empty():
		return "전투 보너스 없음"
	return "전투 보너스: %s" % GameState.format_reward_text(bonus)


func cell_to_position(cell: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE)


func point_to_cell(point: Vector2) -> Vector2i:
	var local := point - BOARD_ORIGIN
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))


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
