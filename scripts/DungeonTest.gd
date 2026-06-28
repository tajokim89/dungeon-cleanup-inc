extends Node2D

const BossTexture = preload("res://assets/sprites/pixellab/주인공/rotations/south.png")
const OFFICE_SCENE_PATH: String = "res://scenes/Office.tscn"
const BATTLE_TEST_SCENE_PATH: String = "res://scenes/BattleTest.tscn"
const PLAYER_START_POSITION: Vector2 = Vector2(230, 520)

const COLOR_BACKGROUND: Color = Color(0.047, 0.052, 0.061)
const COLOR_FLOOR: Color = Color(0.102, 0.118, 0.102)
const COLOR_WALL: Color = Color(0.149, 0.13, 0.095)
const COLOR_STONE: Color = Color(0.18, 0.18, 0.18)
const COLOR_SLIME: Color = Color(0.298, 0.533, 0.267)
const COLOR_TRAP: Color = Color(0.573, 0.439, 0.22)
const COLOR_BONE: Color = Color(0.753, 0.698, 0.573)
const COLOR_EXIT: Color = Color(0.318, 0.373, 0.533)
const COLOR_COMBAT: Color = Color(0.651, 0.263, 0.239)
const COLOR_COMPLETED: Color = Color(0.224, 0.443, 0.329)
const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)
const COLOR_PANEL: Color = Color(0.075, 0.087, 0.075)
const COLOR_PANEL_DARK: Color = Color(0.043, 0.049, 0.043)
const COLOR_PROGRESS: Color = Color(0.494, 0.686, 0.443)

var player: PlayerController
var status_label: Label
var prompt_label: Label
var progress_label: Label
var progress_fill: ColorRect
var completed_task_count: int = 0
var task_completed: Dictionary = {}
var task_visuals: Dictionary = {}
var task_labels: Dictionary = {}
var settlement_applied: bool = false
var current_contract: Dictionary = {}
var total_task_count: int = 0


func _ready() -> void:
	current_contract = GameState.get_selected_contract()
	if current_contract.is_empty():
		current_contract = GameState.get_default_contract()

	build_dungeon()
	if GameState.field_battle_resolved and GameState.last_battle_report != "":
		status_label.text = GameState.last_battle_report
	else:
		status_label.text = "%s: 현장 작업을 처리하세요." % String(current_contract.get("title", "현장"))
	prompt_label.text = "작업 대상 근처에서 E / Space"
	update_progress_label()


func build_dungeon() -> void:
	create_background()
	create_room()
	create_tasks()
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
	create_rect("Floor", Rect2(Vector2(130, 156), Vector2(1010, 444)), COLOR_FLOOR)
	create_wall("NorthWall", Rect2(Vector2(130, 156), Vector2(1010, 30)))
	create_wall("SouthWall", Rect2(Vector2(130, 570), Vector2(1010, 30)))
	create_wall("WestWall", Rect2(Vector2(130, 156), Vector2(30, 444)))
	create_wall("EastWall", Rect2(Vector2(1110, 156), Vector2(30, 444)))

	create_block("BrokenPillarA", Rect2(Vector2(450, 390), Vector2(88, 96)))
	create_block("BrokenPillarB", Rect2(Vector2(760, 220), Vector2(92, 90)))
	create_block("RubbleStack", Rect2(Vector2(850, 520), Vector2(150, 48)))


func create_tasks() -> void:
	var tasks: Array = current_contract.get("tasks", [])
	total_task_count = tasks.size()
	for task: Dictionary in tasks:
		var task_position: Vector2 = task.get("position", Vector2.ZERO)
		var task_size: Vector2 = task.get("size", Vector2(128, 72))
		create_task(
			String(task.get("id", "Task")),
			String(task.get("label", "작업")),
			String(task.get("action", "작업을 처리했습니다.")),
			task_position,
			task_size,
			get_task_color(String(task.get("kind", "")))
		)

	create_combat_event()

	create_interactable(
		"ReturnDoor",
		"사무실 복귀문",
		"사무실로 복귀합니다.",
		Vector2(1030, 250),
		Vector2(92, 116),
		COLOR_EXIT
	)


func create_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.position = GameState.get_field_player_position(PLAYER_START_POSITION)

	var sprite := Sprite2D.new()
	sprite.name = "BossSprite"
	sprite.texture = BossTexture
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
	panel.offset_right = 626
	panel.offset_bottom = 132
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_WALL, 2))
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

	var title := make_label("버려진 하수 던전", 18, COLOR_GOLD)
	title.text = String(current_contract.get("title", "던전 현장"))
	title_box.add_child(title)

	var subtitle := make_label(String(current_contract.get("location", "현장 복구 작업")), 12, COLOR_MUTED)
	title_box.add_child(subtitle)

	header.add_child(make_badge("현장"))

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	layout.add_child(progress_row)

	progress_label = make_label("", 15, COLOR_GOLD)
	progress_label.custom_minimum_size = Vector2(92.0, 20.0)
	progress_row.add_child(progress_label)

	var progress_track := ColorRect.new()
	progress_track.name = "ProgressTrack"
	progress_track.color = COLOR_PANEL_DARK
	progress_track.custom_minimum_size = Vector2(260.0, 8.0)
	progress_row.add_child(progress_track)

	progress_fill = ColorRect.new()
	progress_fill.name = "ProgressFill"
	progress_fill.color = COLOR_PROGRESS
	progress_fill.size = Vector2.ZERO
	progress_track.add_child(progress_fill)

	create_message_panel(canvas)


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
	panel.add_theme_stylebox_override("panel", make_panel_style(COLOR_PANEL, COLOR_WALL, 2))
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


func create_block(node_name: String, rect: Rect2) -> void:
	create_rect("%sVisual" % node_name, rect, COLOR_STONE)

	var block := StaticBody2D.new()
	block.name = node_name
	block.position = rect.position + rect.size * 0.5
	add_child(block)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	block.add_child(collision)


func create_task(node_name: String, label: String, action: String, position: Vector2, size: Vector2, color: Color) -> void:
	var visual := create_interactable(node_name, label, action, position, size, color)
	task_visuals[node_name] = visual
	task_completed[node_name] = false
	if GameState.is_field_task_completed(node_name):
		restore_completed_task(node_name, label)


func create_combat_event() -> void:
	if not GameState.should_spawn_combat_event(current_contract):
		return

	var combat_event := GameState.get_combat_event(current_contract)
	create_interactable(
		"CombatEvent",
		String(combat_event.get("label", "전투 이벤트")),
		String(combat_event.get("action", "현장 전투를 시작합니다.")),
		combat_event.get("position", Vector2(760, 465)),
		combat_event.get("size", Vector2(132, 84)),
		COLOR_COMBAT
	)


func restore_completed_task(task_name: String, task_label: String) -> void:
	task_completed[task_name] = true
	completed_task_count += 1

	var interactable: Interactable = get_node_or_null(task_name) as Interactable
	if interactable != null:
		interactable.action = "%s은 이미 처리했습니다." % task_label

	apply_task_completed_visual(task_name, task_label)


func get_task_color(kind: String) -> Color:
	match kind:
		"slime":
			return COLOR_SLIME
		"trap":
			return COLOR_TRAP
		"bone":
			return COLOR_BONE
		"rubble":
			return COLOR_STONE
		_:
			return COLOR_BONE


func create_interactable(node_name: String, label: String, action: String, position: Vector2, size: Vector2, color: Color) -> ColorRect:
	var visual := create_rect("%sVisual" % node_name, Rect2(position - size * 0.5, size), color)
	var name_label := create_text_label("%sLabel" % node_name, label, position + Vector2(-size.x * 0.5, -size.y * 0.5 - 26), size.x)
	task_labels[node_name] = name_label

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

	return visual


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


func make_badge(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(70.0, 30.0)
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


func update_progress_label() -> void:
	progress_label.text = "작업 %d/%d" % [completed_task_count, total_task_count]
	if progress_fill != null:
		var progress_ratio: float = 1.0 if total_task_count == 0 else float(completed_task_count) / float(total_task_count)
		progress_fill.size = Vector2(260.0 * progress_ratio, 8.0)


func _on_interaction_target_changed(label: String) -> void:
	if label == "":
		prompt_label.text = "작업 대상 근처에서 E / Space"
	else:
		prompt_label.text = "E/Space: %s" % label


func _on_player_interaction_requested(target: Interactable) -> void:
	var target_name: String = String(target.name)
	if target_name == "ReturnDoor":
		try_return_to_office()
		return

	if target_name == "CombatEvent":
		call_deferred("go_to_battle")
		return

	if task_completed.has(target_name):
		complete_task(target_name, target)


func _on_interactable_interacted(label: String, action: String) -> void:
	status_label.text = "%s: %s" % [label, action]


func complete_task(task_name: String, target: Interactable) -> void:
	var was_completed: bool = bool(task_completed.get(task_name, false))
	if was_completed:
		status_label.text = "%s은 이미 처리했습니다." % target.label
		return

	task_completed[task_name] = true
	completed_task_count += 1
	target.action = "%s은 이미 처리했습니다." % target.label
	GameState.mark_field_task_completed(task_name)

	apply_task_completed_visual(task_name, target.label)
	status_label.text = "현장 작업 완료: %s" % target.label
	update_progress_label()

	if completed_task_count >= total_task_count:
		if GameState.should_spawn_combat_event(current_contract):
			prompt_label.text = "남은 전투 이벤트를 처리하세요."
		else:
			prompt_label.text = "복귀문으로 돌아가세요."


func apply_task_completed_visual(task_name: String, task_label: String) -> void:
	var visual: ColorRect = task_visuals[task_name] as ColorRect
	if visual != null:
		visual.color = COLOR_COMPLETED

	var label_node: Label = task_labels[task_name] as Label
	if label_node != null:
		label_node.text = "%s 완료" % task_label
		label_node.add_theme_color_override("font_color", COLOR_MUTED)


func try_return_to_office() -> void:
	if completed_task_count < total_task_count:
		status_label.text = "아직 처리할 작업이 남아 있습니다. %d/%d" % [completed_task_count, total_task_count]
		return

	if GameState.should_spawn_combat_event(current_contract):
		status_label.text = "현장을 방해하는 전투 이벤트를 먼저 해결하세요."
		return

	call_deferred("return_to_office")


func return_to_office() -> void:
	apply_field_settlement()
	get_tree().change_scene_to_file(OFFICE_SCENE_PATH)


func go_to_battle() -> void:
	GameState.set_field_player_position(player.position)
	get_tree().change_scene_to_file(BATTLE_TEST_SCENE_PATH)


func apply_field_settlement() -> void:
	if settlement_applied:
		return

	settlement_applied = true

	GameState.apply_contract_field_report(current_contract, completed_task_count, total_task_count)
