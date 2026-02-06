@tool
extends Control

var plugin: EditorPlugin
var root: TreeItem
var suppress_filesystem_update: bool = false
var filesystem_rebuild_queued: bool = false
var selected_achievement
var selected_achievements = []
var selected_item
var selected_id
var last_visible: bool = false
var _achievements: Array = []

var icon_folder: Texture2D
var icon_save: Texture2D
var icon_remove: Texture2D
var icon_visible: Texture2D
var icon_hidden: Texture2D

var filter_term: String

@onready var tree: Tree = %AchievementsTree
@onready var achievement_notification = %AchievementNotification
@onready var achievement_display = %AchievementDisplay
@onready var id_setting = %IDSetting
@onready var group_id_setting = %GroupIDSetting
@onready var name_setting = %NameSetting
@onready var desc_setting = %DescSetting
@onready var considered_rare_setting = %ConsideredRareSetting
@onready var progressive_setting = %ProgressiveSetting
@onready var progress_goal_setting = %ProgressGoalSetting
@onready var indicate_progress_interval_setting = %IndicateProgressIntervalSetting
@onready var icon_filter_setting = %IconFilterSetting
@onready var icon_setting = %IconSetting
@onready var unachieved_icon_setting = %UnachievedIconSetting
@onready var hidden_icon_setting = %HiddenIconSetting
@onready var hidden_setting = %HiddenSetting
@onready var new_achievement = %NewAchievement
@onready var delete_achievement = %DeleteAchievementButton
@onready var icon_picker = icon_setting.texture_picker

# Settings
@onready var change_folder_button = %AchievementsFolderSetting.path_button
@onready var change_folder_line_edit = %AchievementsFolderSetting.path_button_line_edit
@onready var save_as_json_setting = %SaveAsJsonSetting.toggle
@onready var print_errors_setting = %PrintErrorsSetting.toggle
@onready var print_output_setting = %PrintOutputSetting.toggle

func _ready() -> void:
	if !self.is_part_of_edited_scene():
		plugin = Engine.get_meta("MilestonePlugin")

		self.add_theme_stylebox_override("panel", get_theme_stylebox("Content", "EditorStyles"))

		icon_folder = get_theme_icon("Folder", "EditorIcons")
		icon_save = get_theme_icon("Save", "EditorIcons")
		icon_remove = get_theme_icon("Remove", "EditorIcons")
		icon_visible = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
		icon_hidden = get_theme_icon("GuiVisibilityHidden", "EditorIcons")

		change_folder_line_edit.text = ProjectSettings.get_setting("milestone/general/achievements_path", "res://achievements/")
		change_folder_button.icon = get_theme_icon("Folder", "EditorIcons")
		change_folder_button.pressed.connect(_on_change_folder_button_pressed)
		save_as_json_setting.button_pressed = ProjectSettings.get_setting("milestone/general/save_as_json", true)
		save_as_json_setting.pressed.connect(_on_save_as_json_setting_pressed)

		print_errors_setting.button_pressed = ProjectSettings.get_setting("milestone/debug/print_errors", true)
		print_errors_setting.pressed.connect(_on_print_errors_setting_pressed)

		print_output_setting.button_pressed = ProjectSettings.get_setting("milestone/debug/print_output", true)
		print_output_setting.pressed.connect(_on_print_output_setting_pressed)

		new_achievement.pressed.connect(_on_add_achievement_pressed)

		delete_achievement.icon = get_theme_icon("Remove", "EditorIcons")
		delete_achievement.pressed.connect(_on_delete_achievement_pressed)

		%SettingsContainer.visible = false
		%NotSelectedLabel.visible = true

		icon_filter_setting.option_button.add_item("Inherit")
		icon_filter_setting.option_button.add_item("Nearest")
		icon_filter_setting.option_button.add_item("Linear")
		icon_filter_setting.option_button.add_item("Nearest Mipmap")
		icon_filter_setting.option_button.add_item("Linear Mipmap")
		icon_filter_setting.option_button.add_item("Nearest Mipmap Anisotropic")
		icon_filter_setting.option_button.add_item("Linear Mipmap Anisotropic")
		%FilterLineEdit.right_icon = get_theme_icon("Search", "EditorIcons")
		%FilterLineEdit.text_changed.connect(_on_filter_changed)

		tree.custom_item_clicked.connect(func(_mouse_button_index: int):
			var edited_item = tree.get_edited()
			var item = get_achievement_resource(edited_item.get_metadata(0))
			item.hidden = !item.hidden
			rename_resource(item, item.id)
			
			_update_tree_item_visibility_icon(edited_item, item.hidden)
			
			if selected_achievement and selected_achievement.id == item.id:
				hidden_setting.toggle.button_pressed = item.hidden
				_update_notification(achievement_notification)
				_update_notification(achievement_display)
		)

		tree.item_selected.connect(
			func():
				var item = tree.get_selected()
				selected_id = item.get_metadata(0) if item else null
		)

		tree.item_mouse_selected.connect(
			func(mouse_pos, _mouse_button_index: int) -> void:
				if _mouse_button_index == 2:
					var item = tree.get_item_at_position(mouse_pos)
					if item:
						var popup = PopupMenu.new()
						add_child(popup)
						popup.add_item("Delete", 0)
						popup.position = get_global_mouse_position() + Vector2(0, 20)
						popup.id_pressed.connect(
							func(id) -> void:
								if id == 0:
									_on_delete_achievement_pressed()
						)
						popup.popup()
						await popup.popup_hide
						popup.queue_free()
		)

		tree.multi_selected.connect(
			func(_item: TreeItem, _column: int, _selected: bool) -> void:
				if !_selected:
					selected_achievements.erase(_item)
				else:
					selected_achievements.append(_item)

				selected_achievements = selected_achievements.filter(func(e): return e != null)

				_on_tree_item_clicked()
		)

		tree.empty_clicked.connect(
			func(_pos, _mouse_button_index) -> void:
				tree.deselect_all()
				selected_achievement = null
				selected_achievements.clear()
		)

		_update_tree()
		
		%DocsButton.icon = get_theme_icon("ExternalLink", "EditorIcons")
		%DocsButton.pressed.connect(func():
			OS.shell_open("https://github.com/jelolul/milestone/wiki"))
		%VersionNumber.text = "%s" % plugin.get_version()


func _process(_delta: float) -> void:
	if get_tree().edited_scene_root in [self, owner]:
		return
	
	var selection_count = selected_achievements.size()
	var has_selection = selected_achievement != null
	
	if selection_count > 1:
		%SettingsContainer.visible = false
		%NotSelectedLabel.visible = false
		%MultiSelectingLabel.visible = true
		delete_achievement.disabled = false
		return
	
	if selection_count == 0 or not has_selection:
		%SettingsContainer.visible = false
		%NotSelectedLabel.visible = true
		%MultiSelectingLabel.visible = false
		delete_achievement.disabled = true
		return
	
	%SettingsContainer.visible = true
	%NotSelectedLabel.visible = false
	%MultiSelectingLabel.visible = false
	delete_achievement.disabled = false


func get_all_descendants(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		result.append(child)
		result += get_all_descendants(child)
	return result


#region Natural Sorting
func chunk_string(s: String) -> Array:
	var chunks := []
	var current := ""
	var is_digit := false

	for c in s:
		var digit = (c >= "0" and c <= "9")
		if digit != is_digit:
			if current != "":
				chunks.append(current)
			current = c
			is_digit = digit
		else:
			current += c

	if current != "":
		chunks.append(current)

	return chunks


func comparator(a: String, b: String) -> bool:
	var chunks_a := chunk_string(a)
	var chunks_b := chunk_string(b)

	var n = min(chunks_a.size(), chunks_b.size())

	for i in range(n):
		var ca = chunks_a[i]
		var cb = chunks_b[i]

		if ca.is_valid_int() and cb.is_valid_int():
			var na = int(ca)
			var nb = int(cb)
			if na != nb:
				return na < nb
		elif ca.is_valid_int():
			return true
		elif cb.is_valid_int():
			return false
		elif ca != cb:
			return ca < cb

	return chunks_a.size() < chunks_b.size()
#endregion


func get_achievement_resource(achievement_id: String) -> Achievement:
	if not achievement_id:
		return null
	
	var path = ProjectSettings.get_setting("milestone/general/achievements_path").path_join(achievement_id + ".tres")
	
	if not ResourceLoader.exists(path):
		if ProjectSettings.get_setting("milestone/debug/print_errors"):
			push_error("[Milestone] Achievement resource not found: " + path)
		return null
	
	var achievement: Achievement = load(path)
	
	if not achievement:
		if ProjectSettings.get_setting("milestone/debug/print_errors"):
			push_error("[Milestone] Failed to load achievement: " + path)
		return null
	
	return achievement


func create_achievement_resource() -> Achievement:
	var base_name: String = "new_achievement"
	var resource_name: String = base_name
	var path: String = ""
	var i: int = 1

	var achievements_path = ProjectSettings.get_setting("milestone/general/achievements_path")
	var dir: DirAccess = DirAccess.open(achievements_path)

	while true:
		path = achievements_path.path_join(resource_name + ".tres")
		if not dir.file_exists(path):
			break
		resource_name = base_name + "_" + str(i).pad_zeros(3)
		i += 1

	var _new_achievement := Achievement.new()
	_new_achievement.resource_path = path
	_new_achievement.id = resource_name
	_new_achievement.name = "NEW_ACHIEVEMENT_NAME"
	_new_achievement.description = "NEW_ACHIEVEMENT_DESC"
	_new_achievement.icon = load("uid://dmbey47vfsa2g")

	ResourceSaver.save(_new_achievement, path)
	
	return _new_achievement


func rename_resource(resource: Resource, new_name: String) -> void:
	var old_path := resource.resource_path
	var folder := old_path.get_base_dir()
	var new_path := folder.path_join(new_name + ".tres")

	var dir := DirAccess.open("res://")

	if not dir.file_exists(old_path):
		if ProjectSettings.get_setting("milestone/debug/print_errors"):
			push_error("[Milestone] Original file does not exist: " + old_path)
		return

	if dir.file_exists(new_path):
		ResourceSaver.save(resource, new_path)
		return

	var err := ResourceSaver.save(resource, new_path)
	if err != OK:
		push_error("[Milestone] Failed to save resource: " + str(err))
		return

	dir.remove(old_path)

	resource.set_path(new_path)


func _on_load_achievements() -> void:
	var path = ProjectSettings.get_setting("milestone/general/achievements_path")
	var dir = DirAccess.open(path)
	if not dir:
		return

	var files := []
	dir.list_dir_begin()
	var raw_file = dir.get_next()
	while raw_file != "":
		if raw_file.get_extension() == "tres" or raw_file.get_extension() == "res":
			files.append(raw_file)
		raw_file = dir.get_next()

	files.sort_custom(comparator)

	for file_name in files:
		var resource = load(path.path_join(file_name))
		if resource is Achievement:
			var display_name = file_name.get_file().replace("." + file_name.get_extension(), "")
			if resource.id.is_empty() or display_name.is_empty():
				continue
			var achievement_item = tree.create_item(root)
			achievement_item.set_metadata(0, resource.id)
			achievement_item.set_selectable(0, true)
			achievement_item.set_text(0, display_name)
			achievement_item.set_icon(0, resource.icon)
			achievement_item.set_icon_max_width(0, get_theme_constant("class_icon_size", "Editor"))
			
			achievement_item.set_selectable(1, false)
			achievement_item.set_editable(1, true)
			achievement_item.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
			achievement_item.set_icon_max_width(1, get_theme_constant("class_icon_size", "Editor"))
			_update_tree_item_visibility_icon(achievement_item, resource.hidden)
			
			_achievements.append(achievement_item)

			if display_name == selected_id:
				tree.set_selected(achievement_item, 0)


func _get_selected_tree_item() -> TreeItem:
	var item = tree.get_selected()
	if item:
		return item
	if selected_achievement:
		for t in _achievements:
			if t.get_metadata(0) == selected_achievement.id:
				return t
	return null


func _on_tree_item_clicked() -> void:
	selected_achievement = null
	await get_tree().process_frame
	for _setting in get_all_descendants(%SettingsList):
		if _setting.has_signal("setting_changed"):
			if _setting.setting_changed.is_connected(_on_setting_changed):
				_setting.setting_changed.disconnect(_on_setting_changed)

	selected_item = tree.get_selected()

	if selected_achievements.size() > 1:
		selected_item = tree.get_next_selected(null)

	if selected_item == null or selected_item == root:
		selected_achievements = []
		return

	var item = get_achievement_resource(selected_item.get_metadata(0))

	selected_achievement = item

	id_setting.line_edit.text = item.id
	group_id_setting.line_edit.text = item.group
	name_setting.line_edit.text = item.name
	desc_setting.line_edit.text = item.description
	hidden_setting.toggle.button_pressed = item.hidden
	considered_rare_setting.toggle.button_pressed = item.considered_rare
	progressive_setting.toggle.button_pressed = item.progressive
	progress_goal_setting.spin_box.value = item.progress_goal
	indicate_progress_interval_setting.spin_box.value = item.indicate_progress_interval
	icon_filter_setting.option_button.selected = item.icon_filter
	icon_picker.edited_resource = item.icon
	unachieved_icon_setting.texture_picker.edited_resource = item.unachieved_icon
	hidden_icon_setting.texture_picker.edited_resource = item.hidden_icon

	for _setting in get_all_descendants(%SettingsList):
		if _setting.has_signal("setting_changed"):
			if not _setting.setting_changed.is_connected(_on_setting_changed):
				_setting.setting_changed.connect(_on_setting_changed)
	
	_update_notification(achievement_notification)
	_update_notification(achievement_display)

func _on_setting_changed(_setting_name: String, _value: Variant) -> void:
	_store_changes()

func _store_changes(_achievement = selected_achievement) -> void:
	if !_achievement:
		return
	suppress_filesystem_update = true

	var achievement = get_achievement_resource(_achievement.id)
	if not achievement:
		suppress_filesystem_update = false
		return

	id_setting.line_edit.text = id_setting.line_edit.text.to_snake_case()
	if id_setting.line_edit.text == "":
		id_setting.line_edit.text = "new_achievement"
	achievement.id = id_setting.line_edit.text.to_snake_case()

	achievement.name = name_setting.line_edit.text
	achievement.group = group_id_setting.line_edit.text
	achievement.description = desc_setting.line_edit.text
	achievement.hidden = hidden_setting.toggle.button_pressed
	achievement.considered_rare = considered_rare_setting.toggle.button_pressed
	achievement.progressive = progressive_setting.toggle.button_pressed
	achievement.progress_goal = progress_goal_setting.spin_box.value
	achievement.indicate_progress_interval = indicate_progress_interval_setting.spin_box.value
	achievement.icon_filter = icon_filter_setting.option_button.selected
	achievement.unachieved_icon = unachieved_icon_setting.texture_picker.edited_resource
	achievement.hidden_icon = hidden_icon_setting.texture_picker.edited_resource

	var _icon = icon_picker.edited_resource
	if _icon:
		achievement.icon = _icon

	_update_notification(achievement_notification)
	_update_notification(achievement_display)

	var tree_item = tree.get_selected()
	if tree_item:
		tree_item.set_text(0, achievement.id.to_snake_case())
		tree_item.set_metadata(0, achievement.id.to_snake_case())
		tree_item.set_icon(0, achievement.icon)
		_update_tree_item_visibility_icon(tree_item, achievement.hidden)

	rename_resource(achievement, achievement.id.to_snake_case())
	suppress_filesystem_update = false


func _on_add_achievement_pressed() -> void:
	var new_resource = create_achievement_resource()
	
	var achievement_item = tree.create_item(root)
	achievement_item.set_text(0, new_resource.id)
	achievement_item.set_icon(0, new_resource.icon)
	achievement_item.set_icon_max_width(0, get_theme_constant("class_icon_size", "Editor"))
	achievement_item.set_icon_max_width(1, get_theme_constant("class_icon_size", "Editor"))
	achievement_item.set_metadata(0, new_resource.id)
	_update_tree_item_visibility_icon(achievement_item, false)
	
	_achievements.append(achievement_item)
	
	tree.deselect_all()
	selected_achievements.clear()
	selected_achievement = null

	if achievement_item.visible:
		tree.set_selected(achievement_item, 0)
	
	_show_all_tree_items(root)

func _on_delete_achievement_pressed() -> void:
	var popup = ConfirmationDialog.new()
	self.add_child(popup)
	popup.title = "Delete Achievement"
	popup.dialog_text = "Are you sure you want to delete this achievement?\nThis action cannot be undone."
	popup.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.get_ok_button().text = "Delete"
	popup.get_ok_button().icon = icon_remove
	popup.get_cancel_button().text = "Cancel"
	popup.confirmed.connect(_on_delete_achievement_confirmed)
	popup.popup_centered_ratio(0.1)


func _on_delete_achievement_confirmed() -> void:
	if selected_achievements:
		var items_to_delete = []
		for _selected_item in selected_achievements:
			if _selected_item == root:
				continue
			items_to_delete.append({
				"item": _selected_item,
				"id": _selected_item.get_metadata(0)
			})
		
		for item_data in items_to_delete:
			var resource: Achievement = get_achievement_resource(item_data.id)
			if resource:
				var path := resource.resource_path
				if path != "":
					var dir := DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))
					if dir.file_exists(path):
						var err := dir.remove(path)
						if err != OK:
							push_error("Failed to delete resource: %s" % path)
							continue

				_achievements.erase(item_data.item)
				resource = null
			item_data.item.free()
		
		selected_achievement = null
		selected_achievements.clear()
		tree.deselect_all()
		
		%TabContainer.set_tab_title(0, "Achievements (%d)" % _achievements.size())

func _on_save_button_pressed(_button: Button) -> void:
	_store_changes()

func _on_icon_selected(_resource: Resource) -> void:
	pass

func _update_tree_item_visibility_icon(item: TreeItem, is_hidden: bool) -> void:
	if is_hidden:
		item.set_tooltip_text(1, "Achievement is hidden")
		item.set_icon(1, icon_hidden)
		item.set_icon_modulate(1, get_theme_color("icon_disabled_color", "Editor"))
	else:
		item.set_tooltip_text(1, "Achievement is visible")
		item.set_icon(1, icon_visible)
		item.set_icon_modulate(1, get_theme_color("icon_normal_color", "Editor"))

func _on_save_as_json_setting_pressed() -> void:
	ProjectSettings.set_setting("milestone/general/save_as_json", save_as_json_setting.button_pressed)
	ProjectSettings.save()


func _on_print_errors_setting_pressed() -> void:
	ProjectSettings.set_setting("milestone/debug/print_errors", print_errors_setting.button_pressed)
	ProjectSettings.save()


func _on_print_output_setting_pressed() -> void:
	ProjectSettings.set_setting("milestone/debug/print_output", print_output_setting.button_pressed)
	ProjectSettings.save()


func _on_change_folder_button_pressed() -> void:
	var popup = FileDialog.new()
	self.add_child(popup)
	popup.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	popup.current_dir = ProjectSettings.get_setting("milestone/general/achievements_path")
	popup.access = FileDialog.ACCESS_RESOURCES
	popup.use_native_dialog = true
	popup.dir_selected.connect(_on_folder_selected)
	popup.popup_centered_ratio()


func _on_folder_selected(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_error("[Milestone] Failed to open directory: " + path)
		return

	ProjectSettings.set_setting("milestone/general/achievements_path", path)
	ProjectSettings.save()
	change_folder_line_edit.text = path
	_update_tree()


func _update_tree() -> void:
	if suppress_filesystem_update:
		return
	if !tree:
		return

	selected_item = tree.get_selected()
	selected_id = null
	if selected_item:
		selected_id = selected_item.get_metadata(0)
	elif selected_achievement:
		selected_id = selected_achievement.id

	tree.clear()
	_achievements.clear()

	root = tree.create_item()

	tree.set_hide_root(true)
	tree.set_column_expand(1, false)

	_on_load_achievements()

	if selected_id:
		for item in _achievements:
			if item.get_metadata(0) == selected_id:
				tree.set_selected(item, 0)
				break

	%TabContainer.set_tab_title(0, "Achievements (%d)" % _achievements.size())

func _update_notification(node) -> void:
	var achievement_name = node.achievement_name
	var achievement_description
	var achievement_icon = node.achievement_icon
	var achievement_progress_bar = node.achievement_progress_bar
	var achievement_progress_label = node.achievement_progress_label
	var achievement_action_label = node.achievement_action_label
	var achievement_rare_overlay = node.achievement_rare_overlay
	var achievement_badge
	if node.achievement_badge:
		achievement_badge = node.achievement_badge
	if node.achievement_description:
		achievement_description = node.achievement_description
	var progress_container = node.progress_container

	achievement_name.text = selected_achievement.name

	achievement_icon.texture_filter = selected_achievement.icon_filter
	achievement_icon.texture = selected_achievement.icon
	progress_container.visible = selected_achievement.progressive if !selected_achievement.hidden else false

	achievement_rare_overlay.visible = selected_achievement.considered_rare

	if node.name == "AchievementNotification":
		if selected_achievement.progressive:
			if !selected_achievement.hidden:
				achievement_action_label.text = "Achievement Progress"
		else:
			achievement_action_label.text = "Achievement Unlocked!"
	else:
		achievement_action_label.visible = false
		achievement_description.text = selected_achievement.description
		if selected_achievement.hidden:
			achievement_icon.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
			achievement_icon.texture = selected_achievement.hidden_icon
			achievement_name.text = "???"
			achievement_description.text = "This achievement is hidden."
		else:
			if selected_achievement.unachieved_icon:
				achievement_icon.texture = selected_achievement.unachieved_icon
		achievement_rare_overlay.visible = false

	if selected_achievement.progressive and node.name == "AchievementNotification":
		achievement_progress_bar.max_value = selected_achievement.progress_goal

		achievement_progress_bar.value = selected_achievement.progress_goal * 0.9
		_update_progress_label(achievement_progress_bar.value, achievement_progress_label, node)

	elif selected_achievement.progressive and node.name == "AchievementDisplay":
		achievement_progress_bar.max_value = selected_achievement.progress_goal
		achievement_progress_bar.min_value = 1
		achievement_progress_bar.value = selected_achievement.progress_goal * 0.9
		_update_progress_label(achievement_progress_bar.value, achievement_progress_label, node)

	if achievement_badge:
		achievement_badge.visible = false

func _update_progress_label(value, label: Label, node: Node):
	if selected_achievement:
		if node.name == "AchievementNotification":
			label.text = "(%d/%d)" % [int(value), selected_achievement.progress_goal]
		else:
			label.text = "%d/%d" % [int(value), selected_achievement.progress_goal]

func _on_filter_changed(new_text: String) -> void:
	filter_term = new_text.to_lower()
	apply_filter()

func apply_filter():
	if root == null:
		return
	
	if filter_term.is_empty():
		_show_all_tree_items(root)
		return
	
	_filter_tree_items(root, filter_term)

func _filter_tree_items(item: TreeItem, _filter_term: String) -> bool:
	var should_show = false
	
	var item_text = item.get_text(0).to_lower()
	if _filter_term in item_text:
		should_show = true
	
	var child = item.get_first_child()
	while child != null:
		var child_visible = _filter_tree_items(child, _filter_term)
		if child_visible:
			should_show = true
		child = child.get_next()
	
	item.visible = should_show
	return should_show

func _show_all_tree_items(item: TreeItem):
	%FilterLineEdit.text = ""
	item.visible = true
	var child = item.get_first_child()
	while child != null:
		_show_all_tree_items(child)
		child = child.get_next()

func _on_settings_note_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
