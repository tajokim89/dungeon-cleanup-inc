extends RefCounted
class_name UiAssetStyles

const UI_PLATE_NORMAL: Texture2D = preload("res://assets/sprites/pixellab/black_brass_frame_plate/black_brass_frame_plate/elements/normal_black_brass_frame_plate.png")
const UI_PLATE_HOVER: Texture2D = preload("res://assets/sprites/pixellab/black_brass_frame_plate/black_brass_frame_plate/elements/hover_black_brass_frame_plate.png")
const UI_PLATE_PRESSED: Texture2D = preload("res://assets/sprites/pixellab/black_brass_frame_plate/black_brass_frame_plate/elements/pressed_black_brass_frame_plate.png")
const UI_PLATE_DISABLED: Texture2D = preload("res://assets/sprites/pixellab/black_brass_frame_plate/black_brass_frame_plate/elements/disabled_black_brass_frame_plate.png")
const UI_CONTRACT_NORMAL: Texture2D = preload("res://assets/sprites/pixellab/contract_card/contract_card/elements/normal_empty_contract_card.png")
const UI_CONTRACT_SELECTED: Texture2D = preload("res://assets/sprites/pixellab/contract_card/contract_card/elements/selected_empty_contract_card.png")
const UI_SLOT_NORMAL: Texture2D = preload("res://assets/sprites/pixellab/item_slot/item_slot/elements/normal_empty_item_slot.png")
const UI_SLOT_HOVER: Texture2D = preload("res://assets/sprites/pixellab/item_slot/item_slot/elements/hover_empty_item_slot.png")
const UI_SLOT_SELECTED: Texture2D = preload("res://assets/sprites/pixellab/item_slot/item_slot/elements/selected_empty_item_slot.png")
const UI_SLOT_DISABLED: Texture2D = preload("res://assets/sprites/pixellab/item_slot/item_slot/elements/disabled_empty_item_slot.png")

const COLOR_TEXT: Color = Color(0.902, 0.863, 0.784)
const COLOR_GOLD: Color = Color(0.851, 0.694, 0.373)
const COLOR_MUTED: Color = Color(0.604, 0.573, 0.518)


static func make_texture_style(texture: Texture2D, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


static func apply_common_button_text_style(button: Button, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_GOLD)
	button.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_color_override("font_focus_color", COLOR_GOLD)


static func apply_plate_button_style(
	button: Button,
	active: bool = false,
	font_size: int = 13,
	texture_margin: int = 22,
	content_margin: int = 12
) -> void:
	var normal_texture := UI_PLATE_HOVER if active else UI_PLATE_NORMAL
	apply_common_button_text_style(button, font_size)
	button.add_theme_stylebox_override("normal", make_texture_style(normal_texture, texture_margin, content_margin))
	button.add_theme_stylebox_override("hover", make_texture_style(UI_PLATE_HOVER, texture_margin, content_margin))
	button.add_theme_stylebox_override("pressed", make_texture_style(UI_PLATE_PRESSED, texture_margin, content_margin))
	button.add_theme_stylebox_override("disabled", make_texture_style(UI_PLATE_DISABLED, texture_margin, content_margin))
	button.add_theme_stylebox_override("focus", make_texture_style(UI_PLATE_HOVER, texture_margin, content_margin))


static func apply_contract_card_style(button: Button, active: bool, font_size: int = 13) -> void:
	var normal_texture := UI_CONTRACT_SELECTED if active else UI_CONTRACT_NORMAL
	apply_common_button_text_style(button, font_size)
	button.add_theme_stylebox_override("normal", make_texture_style(normal_texture, 24, 18))
	button.add_theme_stylebox_override("hover", make_texture_style(UI_CONTRACT_SELECTED, 24, 18))
	button.add_theme_stylebox_override("pressed", make_texture_style(UI_CONTRACT_SELECTED, 24, 18))
	button.add_theme_stylebox_override("disabled", make_texture_style(UI_CONTRACT_NORMAL, 24, 18))
	button.add_theme_stylebox_override("focus", make_texture_style(UI_CONTRACT_SELECTED, 24, 18))


static func apply_slot_button_style(button: Button, active: bool, font_size: int = 11) -> void:
	var normal_texture := UI_SLOT_SELECTED if active else UI_SLOT_NORMAL
	apply_common_button_text_style(button, font_size)
	button.add_theme_stylebox_override("normal", make_texture_style(normal_texture, 18, 13))
	button.add_theme_stylebox_override("hover", make_texture_style(UI_SLOT_HOVER, 18, 13))
	button.add_theme_stylebox_override("pressed", make_texture_style(UI_SLOT_SELECTED, 18, 13))
	button.add_theme_stylebox_override("disabled", make_texture_style(UI_SLOT_DISABLED, 18, 13))
	button.add_theme_stylebox_override("focus", make_texture_style(UI_SLOT_SELECTED, 18, 13))
