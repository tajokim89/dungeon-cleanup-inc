extends Area2D
class_name Interactable

signal interacted(label: String, action: String)

@export var label: String = "상호작용 대상"
@export var action: String = "상호작용했습니다."


func interact() -> void:
	interacted.emit(label, action)
