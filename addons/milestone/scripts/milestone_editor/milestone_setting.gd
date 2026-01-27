@tool
extends Node

enum SETTING_TYPE {
	TEXT_INPUT,
	RESOURCE_PICKER,
	TOGGLE,
	SPIN_BOX,
	OPTION_BUTTON,
	BUTTON,
	PATH_BUTTON,
}
@onready var editor_property: EditorProperty
@onready var description: RichTextLabel
@export var setting_name: String = "Setting"
@export_multiline var setting_description: String = ""
# By default, the 'setting_description' variable is  applied on tooltip text.
# This boolean displays it below the EditorProperty.
@export var display_setting_description: bool = false
@export var setting_type: SETTING_TYPE = SETTING_TYPE.TEXT_INPUT

@export_category("Text Input")
@onready var line_edit: LineEdit
@export var text: String = ""
@export var placeholder_text: String = "Placeholder Text"

@export_category("Resource Picker")
@onready var texture_picker: ResourcePicker
@export var base_type: String = "Texture"

@export_category("Toggle")
@onready var toggle: CheckBox
@export var toggle_text: String = "Toggle"

@export_category("Spin Box")
@onready var spin_box: SpinBox
@export var spin_box_min: int = 0
@export var spin_box_max: int = 100
@export var spin_box_step: int = 1
@export var spin_box_value: int = 0
@export var spin_box_prefix: String = ""
@export var spin_box_suffix: String = ""
@export var spin_box_rounded: bool = false

@export_category("Option Button")
@onready var option_button: OptionButton

@export_category("Button")
@onready var button: Button
@export var button_text: String = "Button"

@export_category("Path Button")
@onready var path_button_container: Control
@onready var path_button: Button
@onready var path_button_line_edit: LineEdit
@export var path_button_text: String = "Path Button"
@export var path_button_line_edit_placeholder_text: String = "Path Button"
@export var path_button_line_edit_editable: bool = true

signal setting_changed(setting_name: String, value: Variant)

func _ready() -> void:
	editor_property = %EditorProperty
	description = %SettingDescription
	texture_picker = %TexturePicker
	line_edit = %LineEdit
	toggle = %CheckBox
	spin_box = %SpinBox
	option_button = %OptionButton
	button = %Button
	path_button_container = %PathButton
	path_button = path_button_container.get_node("Button")
	path_button_line_edit = path_button_container.get_node("LineEdit")
	update_setting()
	option_button.clear()
	spin_box.value = spin_box_value

	if setting_type == SETTING_TYPE.TEXT_INPUT:
		line_edit.text_submitted.connect(_on_line_edit_text_changed)
		line_edit.focus_exited.connect(_on_line_edit_text_changed.bind(line_edit.text))
	elif setting_type == SETTING_TYPE.RESOURCE_PICKER:
		texture_picker.resource_changed.connect(_on_texture_picker_resource_changed)
	elif setting_type == SETTING_TYPE.TOGGLE:
		toggle.toggled.connect(_on_toggle_toggled)
	elif setting_type == SETTING_TYPE.SPIN_BOX:
		spin_box.value_changed.connect(_on_spin_box_value_changed)
	elif setting_type == SETTING_TYPE.OPTION_BUTTON:
		option_button.item_selected.connect(_on_option_button_item_selected)
	elif setting_type == SETTING_TYPE.BUTTON:
		button.pressed.connect(_on_button_pressed)
	elif setting_type == SETTING_TYPE.PATH_BUTTON:
		path_button.pressed.connect(_on_path_button_pressed)

func _on_line_edit_text_changed(_new_text: String) -> void:
	emit_signal("setting_changed", setting_name, text)

func _on_texture_picker_resource_changed(_new_resource: Resource) -> void:
	emit_signal("setting_changed", setting_name, texture_picker.edited_resource)

func _on_toggle_toggled(_new_value: bool) -> void:
	emit_signal("setting_changed", setting_name, toggle.pressed)

func _on_spin_box_value_changed(_new_value: float) -> void:
	emit_signal("setting_changed", setting_name, spin_box.value)

func _on_option_button_item_selected(_new_value: int) -> void:
	emit_signal("setting_changed", setting_name, option_button.selected)

func _on_button_pressed() -> void:
	emit_signal("setting_changed", setting_name, button.text)
	
func _on_path_button_pressed() -> void:
	emit_signal("setting_changed", setting_name, path_button.text)

func _process(_delta: float) -> void:
	if !get_tree().edited_scene_root in [self, owner]:
		return
	update_setting()


func update_setting() -> void:
	line_edit.visible = false
	texture_picker.visible = false
	toggle.visible = false
	option_button.visible = false
	spin_box.visible = false
	button.visible = false
	path_button_container.visible = false

	editor_property.label = setting_name
	
	if display_setting_description:
		description.visible = false if setting_description.is_empty() else true
		description.text = setting_description
	else:
		self.tooltip_text = setting_description
	
	if setting_type == SETTING_TYPE.TEXT_INPUT:
		line_edit.visible = true
		line_edit.placeholder_text = placeholder_text
		line_edit.text = text
	elif setting_type == SETTING_TYPE.RESOURCE_PICKER:
		texture_picker.visible = true
		texture_picker.base_type = base_type
	elif setting_type == SETTING_TYPE.TOGGLE:
		toggle.visible = true
	elif setting_type == SETTING_TYPE.SPIN_BOX:
		spin_box.visible = true
		spin_box.min_value = spin_box_min
		spin_box.max_value = spin_box_max
		spin_box.step = spin_box_step
		spin_box.custom_arrow_step = spin_box_step
		spin_box.prefix = spin_box_prefix
		spin_box.suffix = spin_box_suffix
		spin_box.rounded = spin_box_rounded
	elif setting_type == SETTING_TYPE.OPTION_BUTTON:
		option_button.visible = true
	elif setting_type == SETTING_TYPE.BUTTON:
		button.visible = true
		button.text = button_text
	elif setting_type == SETTING_TYPE.PATH_BUTTON:
		path_button_container.visible = true
		path_button_line_edit.placeholder_text = path_button_line_edit_placeholder_text
		path_button_line_edit.editable = path_button_line_edit_editable
		path_button.text = path_button_text
