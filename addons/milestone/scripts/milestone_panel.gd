@tool
extends Control

var plugin: EditorPlugin

@onready var tree: Tree = %AchievementsTree
var root: TreeItem

var _achievements: Array = []

var selected_achievement

@onready var achievement_notification = %AchievementNotification
@onready var achievement_display = %AchievementDisplay

@onready var id_setting = %IDSetting
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
@onready var delete_achievement = %DeleteAchievement
@onready var delete_achievement_2 = %DeleteAchievementButton

@onready var icon_picker = icon_setting.texture_picker

@onready var save_button = %SaveButton

# Settings
@onready var change_folder_button = %AchievementsFolderSetting.path_button
@onready var change_folder_line_edit = %AchievementsFolderSetting.path_button_line_edit
@onready var save_as_json_setting = %SaveAsJsonSetting.toggle

var selected_achievements = []

func _ready() -> void:
	plugin = Engine.get_meta("MilestonePlugin")
	if !get_tree().edited_scene_root in [self, owner]:
		EditorInterface.get_resource_filesystem().filesystem_changed.connect(_update_tree)

		# Settings signals
		change_folder_line_edit.text = ProjectSettings.get_setting("milestone/general/achievements_path", "res://achievements/")
		change_folder_button.icon = get_theme_icon("Folder", "EditorIcons")
		change_folder_button.pressed.connect(_on_change_folder_button_pressed)
		save_as_json_setting.button_pressed = ProjectSettings.get_setting("milestone/general/save_as_json", true)
		save_as_json_setting.pressed.connect(_on_save_as_json_setting_pressed)

		save_button.icon = get_theme_icon("Save", "EditorIcons")
		save_button.pressed.connect(_on_save_button_pressed.bind(save_button))

		new_achievement.icon = get_theme_icon("Add", "EditorIcons")
		new_achievement.pressed.connect(_on_add_achievement_pressed.bind("new_achievement"))

		delete_achievement.icon = get_theme_icon("Remove", "EditorIcons")
		delete_achievement.pressed.connect(_on_delete_achievement_pressed)
		delete_achievement_2.icon = get_theme_icon("Remove", "EditorIcons")
		delete_achievement_2.pressed.connect(_on_delete_achievement_pressed)

		%SettingsContainer.visible = false
		save_button.disabled = true
		%NotSelectedLabel.visible = true

		icon_filter_setting.option_button.add_item("Inherit")
		icon_filter_setting.option_button.add_item("Nearest")
		icon_filter_setting.option_button.add_item("Linear")
		icon_filter_setting.option_button.add_item("Nearest Mipmap")
		icon_filter_setting.option_button.add_item("Linear Mipmap")
		icon_filter_setting.option_button.add_item("Nearest Mipmap Anisotropic")
		icon_filter_setting.option_button.add_item("Linear Mipmap Anisotropic")


		tree.item_mouse_selected.connect(func(mouse_pos, _mouse_button_index: int) -> void:
			if _mouse_button_index == 2:
				var item = tree.get_item_at_position(mouse_pos)
				if item:
					var popup = PopupMenu.new()
					add_child(popup)
					popup.add_item("Delete", 0)
					popup.position = get_global_mouse_position() + Vector2(0, 20)
					popup.id_pressed.connect(func(id) -> void:
						if id == 0:
							_on_delete_achievement_pressed()
					)
					popup.popup()
		)

		tree.multi_selected.connect(func(_item: TreeItem, _column: int, _selected: bool) -> void:
			if !_selected:
				selected_achievements.erase(_item)
			else:
				selected_achievements.append(_item)

			selected_achievements = selected_achievements.filter(func(e): return e != null)

			_on_tree_item_clicked()
		)

		tree.empty_clicked.connect(func(_pos, _mouse_button_index) -> void:
			tree.deselect_all()
			selected_achievement = null
			selected_achievements.clear()
		)

		_update_tree()

	%VersionNumber.text = "%s" % plugin.get_version()

func get_all_descendants(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		result.append(child)
		result += get_all_descendants(child)
	return result

func _on_load_achievements() -> void:
	var path = ProjectSettings.get_setting("milestone/general/achievements_path")
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.get_extension() == "tres" or file.get_extension() == "res":
				var resource = load(path + file)
				if resource is Achievement:
					var _file = file.get_file().replace(str(".", file.get_extension()), "")
					if resource.id.is_empty() or _file.is_empty():
						continue
					var achievement_item = tree.create_item(root)
					achievement_item.set_text(0, _file)
					achievement_item.set_icon(0, resource.icon)
					achievement_item.set_selectable(0, true)
					achievement_item.set_icon_max_width(0, 16)
					achievement_item.set_metadata(0, resource.id)
					if resource.hidden:
						achievement_item.set_icon(1, resource.hidden_icon)
					else:
						achievement_item.set_icon(1, null)
					achievement_item.set_selectable(1, false)
					_achievements.append(achievement_item)

					if _file == selected_id:
						tree.set_selected(achievement_item, 0)
			file = dir.get_next()


	%AchievementsCount.text = "# of achievements loaded: %d" % _achievements.size()

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
			if _setting.setting_changed.is_connected(_on_setting_changed):
				_setting.setting_changed.disconnect(_on_setting_changed)
				_setting.setting_changed.connect(_on_setting_changed)
			else:
				_setting.setting_changed.connect(_on_setting_changed)
	
	save_button.disabled = false


	if achievement_notif_tween and achievement_notif_tween.is_running():
		achievement_notif_tween.stop()

	_update_notification(achievement_notification)
	_update_notification(achievement_display)

func _on_setting_changed(_setting_name: String, _value: Variant) -> void:
	_store_changes()

func _store_changes(_achievement = selected_achievement) -> void:
	if !_achievement:
		return

	var achievement = get_achievement_resource(_achievement.id)
	id_setting.line_edit.text = id_setting.line_edit.text.to_snake_case()
	if id_setting.line_edit.text == "":
		id_setting.line_edit.text = "new_achievement"
	
	achievement.id = id_setting.find_child("LineEdit").text.to_snake_case()
	tree.get_selected().set_text(0, achievement.id.to_snake_case())
	tree.get_selected().set_metadata(0, achievement.id.to_snake_case())
	achievement.name = name_setting.line_edit.text
	achievement.description = desc_setting.line_edit.text
	achievement.hidden = hidden_setting.toggle.button_pressed
	achievement.considered_rare = considered_rare_setting.toggle.button_pressed
	achievement.progressive = progressive_setting.toggle.button_pressed
	achievement.progress_goal = progress_goal_setting.spin_box.value
	achievement.indicate_progress_interval = indicate_progress_interval_setting.spin_box.value
	achievement.icon_filter = icon_filter_setting.option_button.selected
	achievement.unachieved_icon = unachieved_icon_setting.texture_picker.edited_resource
	achievement.hidden_icon = hidden_icon_setting.texture_picker.edited_resource
	if achievement.hidden:
		tree.get_selected().set_icon(1, achievement.hidden_icon)
	else:
		tree.get_selected().set_icon(1, null)

	
	var _icon = icon_picker.edited_resource
	if _icon:
		achievement.icon = _icon
		tree.get_selected().set_icon(0, _icon)

	_update_notification(achievement_notification)
	_update_notification(achievement_display)
	
	rename_resource(achievement, achievement.id.to_snake_case())

func _on_add_achievement_pressed(achievement_name: String = "new_achievement") -> void:
	var achievement_item = tree.create_item(root)
	achievement_item.set_text(0, achievement_name.to_snake_case())
	achievement_item.set_icon_max_width(0, 16)
	achievement_item.set_icon_max_width(1, 16)
	achievement_item.set_metadata(0, achievement_name.to_snake_case())
	achievement_item.set_icon(1, hidden_icon_setting.texture_picker.edited_resource)
	_achievements.append(achievement_item)
	selected_achievements.clear()
	selected_achievements.append(achievement_item)
	create_achievement_resource()

func _on_delete_achievement_pressed() -> void:
	var popup = ConfirmationDialog.new()
	self.add_child(popup)
	popup.title = "Delete Achievement"
	popup.dialog_text = "Are you sure you want to delete this achievement?\nThis action cannot be undone."
	popup.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.get_ok_button().text = "Delete"
	popup.get_ok_button().icon = get_theme_icon("Remove", "EditorIcons")
	popup.get_cancel_button().text = "Cancel"
	popup.confirmed.connect(_on_delete_achievement_confirmed)
	popup.popup_centered_ratio(0.1)

func _on_delete_achievement_confirmed() -> void:
	if selected_achievements:
		for _selected_item in selected_achievements:
			if _selected_item == root:
				continue
			var resource: Achievement = get_achievement_resource(_selected_item.get_metadata(0))
			if resource:
				var path := resource.resource_path
				if path != "":
					var dir := DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))
					if dir.file_exists(path):
						var err := dir.remove(path)
						if err != OK:
							push_error("Failed to delete resource: %s" % path)
							return

				_achievements.erase(_selected_item.get_metadata(0))
				resource = null
			_selected_item.free()
			selected_achievement = null
		tree.deselect_all()
		EditorInterface.get_resource_filesystem().scan()
		_update_tree()

func _on_save_button_pressed(_button: Button) -> void:
	_store_changes()
	
func get_achievement_resource(achievement_id: String) -> Achievement:
	if !achievement_id:
		return null

	var achievement: Achievement = load(ProjectSettings.get_setting("milestone/general/achievements_path") + achievement_id + ".tres")

	if !achievement:
		return null

	return achievement
	
func create_achievement_resource() -> Achievement:
	var base_name: String = "new_achievement"
	var resource_name: String = base_name
	var path: String = ""
	var i: int = 1
	
	var dir: DirAccess = DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))


	while true:
		path = str(ProjectSettings.get_setting("milestone/general/achievements_path")) + resource_name + ".tres"
		if not dir.file_exists(path):
			break
		resource_name = base_name + "_" + str(i).pad_zeros(3)
		i += 1

	var _new_achievement := Achievement.new()
	_new_achievement.id = resource_name
	_new_achievement.name = "NEW_ACHIEVEMENT_NAME"
	_new_achievement.description = "NEW_ACHIEVEMENT_DESC"
	_new_achievement.icon = load("res://addons/milestone/assets/missing_icon.svg")

	ResourceSaver.save(_new_achievement, path)
	_new_achievement.set_path(path)
	_update_tree()
	return _new_achievement

func _on_icon_selected(_resource: Resource) -> void:
	pass

func _on_save_as_json_setting_pressed() -> void:
	ProjectSettings.set_setting("milestone/general/save_as_json", save_as_json_setting.button_pressed)
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
	EditorInterface.get_resource_filesystem().scan()
	_update_tree()

func rename_resource(resource: Resource, new_name: String) -> void:
	var old_path := resource.resource_path
	var folder := old_path.get_base_dir()
	var new_path := folder.path_join(new_name + ".tres")
	
	var dir := DirAccess.open("res://")
	
	if not dir.file_exists(old_path):
		# push_error("[Milestone] Original file does not exist: " + old_path)
		return

	if dir.file_exists(new_path):
		# print("[Milestone] A file with that name already exists: " + new_path)
		return

	var err := ResourceSaver.save(resource, new_path)
	if err != OK:
		push_error("[Milestone] Failed to save resource: " + str(err))
		return

	dir.remove(old_path)

	resource.set_path(new_path)

	EditorInterface.get_resource_filesystem().scan()

var selected_item
var selected_id

func _update_tree() -> void:
	await get_tree().process_frame
	if !tree:
		return

	selected_item = tree.get_selected()
	selected_id = selected_item.get_metadata(0) if selected_item else null

	tree.clear()
	_achievements.clear()

	root = tree.create_item()
	root.set_text(0, "Achievements")
	root.set_icon_max_width(0, 16)
	root.set_icon(0, load("res://addons/milestone/assets/icon-x16.svg"))
	root.set_selectable(0, false)
	tree.set_hide_root(true)
	tree.set_column_expand(1, false)

	_on_load_achievements()

var achievement_notif_tween: Tween

func _update_notification(node) -> void:
	var achievement_name = node.find_child("AchievementName")
	var achievement_icon = node.find_child("AchievementIcon")
	var achievement_progress_bar = node.find_child("AchievementProgressBar")
	var achievement_progress_label = node.find_child("AchievementProgressLabel")
	var achievement_action_label = node.find_child("AchievementActionLabel")
	var achievement_rare_overlay = node.find_child("AchievementRareOverlay")
	var achievement_badge = node.find_child("AchievementBadge")
	var progress_container = node.find_child("ProgressContainer")
	var tween

	achievement_name.text = selected_achievement.name

	achievement_icon.texture_filter = selected_achievement.icon_filter
	achievement_icon.texture = selected_achievement.icon

	progress_container.visible = selected_achievement.progressive

	achievement_rare_overlay.visible = selected_achievement.considered_rare
	
	if node.name == "AchievementNotification":
		tween = achievement_notif_tween
		if tween:
			tween.stop()
			tween.kill()
		if selected_achievement.progressive:
			achievement_action_label.text = "Achievement Progress"
		else:
			achievement_action_label.text = "Achievement Unlocked!"
	else:
		achievement_action_label.visible = false
		node.find_child("AchievementDescription").text = selected_achievement.description
		if selected_achievement.hidden:
			achievement_icon.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
			achievement_icon.texture = selected_achievement.hidden_icon
			achievement_name.text = "???"
			node.find_child("AchievementDescription").text = "This achievement is hidden."
		else:
			if selected_achievement.unachieved_icon:
				achievement_icon.texture = selected_achievement.unachieved_icon
		achievement_rare_overlay.visible = false

	if selected_achievement.progressive and node.name == "AchievementNotification":
		achievement_progress_bar.max_value = selected_achievement.progress_goal

		achievement_progress_bar.value = 0
		tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR).set_loops(-1)
		
		tween.tween_property(achievement_progress_bar, "value", selected_achievement.progress_goal, 1)
		tween.parallel().tween_method(self._update_progress_label.bind(achievement_progress_label, node), 0, selected_achievement.progress_goal, 1)

		tween.tween_property(achievement_progress_bar, "value", 0, 0)
		tween.parallel().tween_method(self._update_progress_label.bind(achievement_progress_label, node), selected_achievement.progress_goal, 0, 0)

		achievement_notif_tween = tween

	elif selected_achievement.progressive and node.name == "AchievementDisplay":
		achievement_progress_bar.min_value = 1
		achievement_progress_bar.max_value = selected_achievement.progress_goal
		achievement_progress_bar.value = selected_achievement.progress_goal / 3
		_update_progress_label(achievement_progress_bar.value, achievement_progress_label, node)

	if achievement_badge:
		achievement_badge.visible = false
	
func _update_progress_label(value, label: Label, node: Node):
	if selected_achievement:
		if node.name == "AchievementNotification":
			label.text = "(%d/%d)" % [int(value), selected_achievement.progress_goal]
		else:
			label.text = "%d/%d" % [int(value), selected_achievement.progress_goal]

var last_visible: bool = false

func _process(_delta: float) -> void:
	if get_tree().edited_scene_root in [self, owner]:
		return

	if selected_achievements.size() > 1:
		%SettingsContainer.visible = false
		%NotSelectedLabel.visible = false
		%MultiSelectingLabel.visible = true
		save_button.disabled = true
		delete_achievement.disabled = false
		delete_achievement_2.disabled = false
	if selected_achievements.size() == 0 or selected_achievement == null:
		%SettingsContainer.visible = false
		%NotSelectedLabel.visible = true
		%MultiSelectingLabel.visible = false
		save_button.disabled = true
		delete_achievement.disabled = true
		delete_achievement_2.disabled = true
	if selected_achievements.size() == 1 and selected_achievement != null:
		%SettingsContainer.visible = true
		%NotSelectedLabel.visible = false
		%MultiSelectingLabel.visible = false
		save_button.disabled = false
		delete_achievement.disabled = false
		delete_achievement_2.disabled = false

	if self.visible != last_visible:
		last_visible = self.visible

		if !self.visible:
			if achievement_notif_tween and achievement_notif_tween.is_running():
				achievement_notif_tween.stop()
		else:
			if achievement_notif_tween:
				tree.deselect_all()