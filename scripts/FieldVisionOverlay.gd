extends Control
class_name FieldVisionOverlay

@export var visible_radius: float = 330.0
@export var fade_radius: float = 92.0
@export var world_cell_size: float = 56.0
@export var unexplored_alpha: float = 0.95
@export var explored_alpha: float = 0.62
@export var edge_alpha: float = 0.35

var tracked_target: Node2D
var explored_cells: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	mark_visible_area_explored()
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if tracked_target == null or not is_instance_valid(tracked_target):
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, unexplored_alpha))
		return

	var canvas_transform := get_viewport().get_canvas_transform()
	var inverse_transform := canvas_transform.affine_inverse()
	var player_world_position := tracked_target.global_position
	var screen_step: float = maxf(20.0, world_cell_size * canvas_transform.get_scale().x)

	var y: float = 0.0
	while y < viewport_size.y:
		var x: float = 0.0
		while x < viewport_size.x:
			var screen_center := Vector2(x + screen_step * 0.5, y + screen_step * 0.5)
			var world_position: Vector2 = inverse_transform * screen_center
			var alpha := get_fog_alpha(world_position, player_world_position)
			if alpha > 0.01:
				var color := get_fog_color(world_position, alpha)
				draw_rect(Rect2(Vector2(x, y), Vector2(screen_step + 1.0, screen_step + 1.0)), color)
			x += screen_step
		y += screen_step


func mark_visible_area_explored() -> void:
	if tracked_target == null or not is_instance_valid(tracked_target):
		return

	var player_cell := get_world_cell(tracked_target.global_position)
	var cell_radius := ceili(visible_radius / world_cell_size)
	for y_offset in range(-cell_radius, cell_radius + 1):
		for x_offset in range(-cell_radius, cell_radius + 1):
			var cell := player_cell + Vector2i(x_offset, y_offset)
			var cell_center := get_cell_world_center(cell)
			if tracked_target.global_position.distance_to(cell_center) <= visible_radius:
				explored_cells[get_cell_key(cell)] = true


func get_fog_alpha(world_position: Vector2, player_world_position: Vector2) -> float:
	var distance := player_world_position.distance_to(world_position)
	var clear_radius := maxf(0.0, visible_radius - fade_radius)
	if distance <= clear_radius:
		return 0.0
	if distance <= visible_radius:
		var fade_ratio := (distance - clear_radius) / fade_radius
		return lerpf(0.0, edge_alpha, fade_ratio)

	var cell_key := get_cell_key(get_world_cell(world_position))
	if explored_cells.has(cell_key):
		return explored_alpha
	return unexplored_alpha


func get_fog_color(world_position: Vector2, alpha: float) -> Color:
	var cell := get_world_cell(world_position)
	var noise := get_cell_noise(cell)
	var value := lerpf(0.0, 0.035, noise)
	return Color(value, value * 1.08, value * 1.22, alpha)


func get_world_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / world_cell_size),
		floori(world_position.y / world_cell_size)
	)


func get_cell_world_center(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * world_cell_size,
		(float(cell.y) + 0.5) * world_cell_size
	)


func get_cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func get_cell_noise(cell: Vector2i) -> float:
	var value := int(abs(cell.x * 928371 + cell.y * 689287 + 1376312589)) % 1000
	return float(value) / 999.0
