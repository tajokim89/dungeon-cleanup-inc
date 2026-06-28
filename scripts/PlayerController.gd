extends CharacterBody2D
class_name PlayerController

signal interaction_target_changed(label: String)
signal interaction_requested(target: Interactable)

@export var move_speed: float = 190.0

const CHARACTER_ANIMATION_ROOT: String = "res://assets/sprites/pixellab/주인공/animations"
const DIRECTION_NAMES: Array[String] = [
	"south",
	"south-east",
	"east",
	"north-east",
	"north",
	"north-west",
	"west",
	"south-west",
]
const IDLE_FRAME_COUNT: int = 4
const WALK_FRAME_COUNT: int = 6
const IDLE_FPS: float = 4.0
const WALK_FPS: float = 8.0
const DEFAULT_FACING: String = "south"

var nearby_interactables: Array[Interactable] = []
var character_sprite: AnimatedSprite2D
var facing_direction: String = DEFAULT_FACING


func _ready() -> void:
	setup_character_sprite()

	var interaction_area: Node = get_node_or_null("InteractionArea")
	if interaction_area is Area2D:
		interaction_area.area_entered.connect(_on_interaction_area_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_area_exited)


func _physics_process(_delta: float) -> void:
	var direction := get_input_direction()

	velocity = direction.normalized() * move_speed
	update_character_animation(direction)
	move_and_slide()


func setup_character_sprite() -> void:
	character_sprite = get_node_or_null("BossSprite") as AnimatedSprite2D
	if character_sprite == null:
		return

	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for direction_name: String in DIRECTION_NAMES:
		add_animation_frames(
			sprite_frames,
			"idle_%s" % direction_name,
			"Breathing_Idle",
			direction_name,
			IDLE_FRAME_COUNT,
			IDLE_FPS
		)
		add_animation_frames(
			sprite_frames,
			"walk_%s" % direction_name,
			"Walking",
			direction_name,
			WALK_FRAME_COUNT,
			WALK_FPS
		)

	character_sprite.sprite_frames = sprite_frames
	play_character_animation("idle_%s" % facing_direction)


func add_animation_frames(
	sprite_frames: SpriteFrames,
	animation_name: String,
	animation_folder: String,
	direction_name: String,
	frame_count: int,
	fps: float
) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, fps)

	for frame_index in range(frame_count):
		var texture_path := "%s/%s/%s/frame_%03d.png" % [
			CHARACTER_ANIMATION_ROOT,
			animation_folder,
			direction_name,
			frame_index,
		]
		var texture := load(texture_path) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)


func get_input_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	return direction


func update_character_animation(direction: Vector2) -> void:
	if character_sprite == null:
		return

	if direction != Vector2.ZERO:
		facing_direction = get_direction_name(direction)
		play_character_animation("walk_%s" % facing_direction)
	else:
		play_character_animation("idle_%s" % facing_direction)


func get_direction_name(direction: Vector2) -> String:
	var horizontal := signi(roundi(direction.x))
	var vertical := signi(roundi(direction.y))

	if vertical < 0 and horizontal > 0:
		return "north-east"
	if vertical < 0 and horizontal < 0:
		return "north-west"
	if vertical > 0 and horizontal > 0:
		return "south-east"
	if vertical > 0 and horizontal < 0:
		return "south-west"
	if vertical < 0:
		return "north"
	if vertical > 0:
		return "south"
	if horizontal > 0:
		return "east"
	if horizontal < 0:
		return "west"
	return facing_direction


func play_character_animation(animation_name: String) -> void:
	if character_sprite == null or character_sprite.sprite_frames == null:
		return
	if not character_sprite.sprite_frames.has_animation(animation_name):
		return
	if character_sprite.animation == animation_name and character_sprite.is_playing():
		return

	character_sprite.play(animation_name)


func signi(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


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
