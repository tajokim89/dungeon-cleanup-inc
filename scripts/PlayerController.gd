extends CharacterBody2D
class_name PlayerController

signal interaction_target_changed(label: String)
signal interaction_requested(target: Interactable)

@export var move_speed: float = 190.0

var nearby_interactables: Array[Interactable] = []


func _ready() -> void:
	var interaction_area: Node = get_node_or_null("InteractionArea")
	if interaction_area is Area2D:
		interaction_area.area_entered.connect(_on_interaction_area_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_area_exited)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	velocity = direction.normalized() * move_speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and is_interact_key(key_event.keycode):
			var target: Interactable = get_current_interactable()
			if target != null:
				target.interact()
				interaction_requested.emit(target)


func is_interact_key(keycode: Key) -> bool:
	return keycode == KEY_E or keycode == KEY_SPACE


func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area is Interactable:
		var interactable: Interactable = area as Interactable
		if not nearby_interactables.has(interactable):
			nearby_interactables.append(interactable)
		emit_current_target()


func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area is Interactable:
		nearby_interactables.erase(area)
		emit_current_target()


func get_current_interactable() -> Interactable:
	if nearby_interactables.is_empty():
		return null
	return nearby_interactables[nearby_interactables.size() - 1]


func emit_current_target() -> void:
	var target: Interactable = get_current_interactable()
	if target == null:
		interaction_target_changed.emit("")
	else:
		interaction_target_changed.emit(target.label)
