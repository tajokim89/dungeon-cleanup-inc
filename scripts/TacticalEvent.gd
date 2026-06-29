extends Control

const UiAssetStyles = preload("res://scripts/UiAssetStyles.gd")

signal tactical_completed(success: bool)

const GRID_SIZE: int = 5
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

var turn: int = 1
var max_turn: int = 3
var player_pos: Vector2i = Vector2i(2, 2)
var exit_pos: Vector2i = Vector2i(4, 1)
var player_hp: int = 2
var carrying_body: bool = true
var pollution_tiles: Array[Vector2i] = [Vector2i(2, 3), Vector2i(3, 1)]

var finished: bool = false
var event_success: bool = false
var message: String = "시체 포대를 들고 출구까지 이동하세요."


func _ready() -> void:
	build_ui()


func build_ui() -> void:
	clear_ui()

	var background := ColorRect.new()
	background.name = "TacticalBackground"
	background.color = COLOR_BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.name = "TacticalLayout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 40
	layout.offset_top = 32
	layout.offset_right = -40
	layout.offset_bottom = -32
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	var header := make_panel_container(COLOR_PANEL_ALT, COLOR_BORDER, 3)
	layout.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 16)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)

	var header_layout := VBoxContainer.new()
	header_layout.add_theme_constant_override("separation", 6)
	header_margin.add_child(header_layout)

	var title := make_label("전술 이벤트: 시체 포대 회수", 28, COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_layout.add_child(title)

	var status: Label = make_label("Turn %d/%d | HP %d | 목표: 시체 포대 들고 출구 도달" % [
		turn,
		max_turn,
		player_hp,
	], 17, COLOR_TEXT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_layout.add_child(status)

	var message_color: Color = COLOR_DANGER if message.contains("오염") or message.contains("실패") else COLOR_MUTED
	var message_label: Label = make_label(message, 16, message_color)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(message_label)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	layout.add_child(grid)

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos := Vector2i(x, y)
			var cell := make_cell(pos)
			grid.add_child(cell)

	if finished:
		var result_text: String = "성공: 포대를 회수해 출구로 빠져나왔습니다." if event_success else "실패: 회수팀이 더 버티지 못했습니다."
		var result_color: Color = COLOR_GREEN if event_success else COLOR_DANGER
		var result_label: Label = make_label(result_text, 18, result_color)
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(result_label)

		var return_button := make_button("경영 정산으로 돌아가기")
		return_button.pressed.connect(_on_return_pressed)
		layout.add_child(return_button)
		return

	var controls := GridContainer.new()
	controls.columns = 3
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(controls)

	controls.add_child(make_disabled_button(""))
	controls.add_child(make_move_button("상", Vector2i(0, -1)))
	controls.add_child(make_disabled_button(""))
	controls.add_child(make_move_button("좌", Vector2i(-1, 0)))
	controls.add_child(make_disabled_button("이동"))
	controls.add_child(make_move_button("우", Vector2i(1, 0)))
	controls.add_child(make_disabled_button(""))
	controls.add_child(make_move_button("하", Vector2i(0, 1)))
	controls.add_child(make_disabled_button(""))


func clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func get_cell_text(pos: Vector2i) -> String:
	if pos == player_pos:
		return "팀\n포대" if carrying_body else "팀"
	if pos == exit_pos:
		return "출"
	if pollution_tiles.has(pos):
		return "오염"
	return "·"


func make_cell(pos: Vector2i) -> Button:
	var cell := Button.new()
	cell.text = get_cell_text(pos)
	cell.disabled = true
	cell.custom_minimum_size = Vector2(76, 58)
	cell.add_theme_color_override("font_disabled_color", get_cell_text_color(pos))
	cell.add_theme_stylebox_override("disabled", make_panel_style(get_cell_bg_color(pos), get_cell_border_color(pos), 2))
	return cell


func get_cell_bg_color(pos: Vector2i) -> Color:
	if pos == player_pos:
		return COLOR_GREEN
	if pos == exit_pos:
		return COLOR_GOLD
	if pollution_tiles.has(pos):
		return COLOR_PURPLE
	return COLOR_PANEL


func get_cell_border_color(pos: Vector2i) -> Color:
	if pos == player_pos:
		return COLOR_GOLD
	if pos == exit_pos:
		return COLOR_GREEN
	if pollution_tiles.has(pos):
		return COLOR_DANGER
	return COLOR_BORDER


func get_cell_text_color(pos: Vector2i) -> Color:
	if pos == player_pos or pos == exit_pos:
		return COLOR_BACKGROUND
	return COLOR_TEXT


func make_move_button(text: String, delta: Vector2i) -> Button:
	var button := make_button(text)
	button.pressed.connect(_on_move_pressed.bind(delta))
	return button


func make_disabled_button(text: String) -> Button:
	var button := make_button(text)
	button.disabled = true
	return button


func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(92, 44)
	UiAssetStyles.apply_plate_button_style(button)
	return button


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


func _on_move_pressed(delta: Vector2i) -> void:
	if finished:
		return

	var next_pos: Vector2i = player_pos + delta
	if next_pos.x < 0 or next_pos.x >= GRID_SIZE or next_pos.y < 0 or next_pos.y >= GRID_SIZE:
		message = "벽입니다. 다른 방향으로 이동하세요."
		build_ui()
		return

	player_pos = next_pos
	message = "포대를 끌고 이동했습니다."

	if pollution_tiles.has(player_pos):
		player_hp -= 1
		message = "오염 타일을 밟았습니다. HP -1"

	if player_hp <= 0:
		finish_event(false)
		return

	if player_pos == exit_pos and carrying_body:
		finish_event(true)
		return

	if turn >= max_turn:
		finish_event(false)
		return

	turn += 1
	build_ui()


func finish_event(success: bool) -> void:
	finished = true
	event_success = success
	message = "전술 이벤트 성공" if success else "전술 이벤트 실패"
	build_ui()


func _on_return_pressed() -> void:
	tactical_completed.emit(event_success)
