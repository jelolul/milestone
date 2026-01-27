extends Control

const ACHIEVEMENT_DISPLAY = preload("uid://b2ygwvy3dv00a")

@export var achievement_notifier: AchievementNotifier

@export var achievements_unlocked_label: Label
@export var achievements_unlocked_percentage: Label
@export var achievements_progress_bar: ProgressBar

@export var unlocked_container: Node
@export var unlocked_achievements_container: Node

@export var locked_container: Node
@export var locked_achievements_container: Node
@export var hidden_achievements_container: Node

func _ready() -> void:
	%UnlockAllAchievements.pressed.connect(AchievementManager.unlock_all_achievements)
	%ResetAchievements.pressed.connect(AchievementManager.reset_achievements)
	%CloseGame.pressed.connect(get_tree().quit)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.achievements_reset.connect(_on_achievements_reset)
	AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

	await AchievementManager.achievements_loaded
	AchievementManager.unlock_achievement("game_launch")

	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)

func _on_achievement_unlocked(achievement_id: String) -> void:
	if AchievementManager.achievements_list[achievement_id].hidden:
		for child in hidden_achievements_container.get_children():
			if child.achievement_id == achievement_id:
				child.visible = true
				child.get_parent().remove_child(child)

				var index = 0
				for sibling in unlocked_achievements_container.get_children():
					var sibling_data = AchievementManager.achievements.get(sibling.achievement_id, null)
					var achievement_data = AchievementManager.achievements.get(achievement_id, null)

					if sibling_data.unlocked_date < achievement_data.unlocked_date:
						break
					index += 1
				

				unlocked_achievements_container.add_child(child)
				unlocked_achievements_container.move_child(child, index)
				break
	else:
		for child in locked_achievements_container.get_children():
			if child.achievement_id == achievement_id:
				child.visible = true
				child.get_parent().remove_child(child)

				var index = 0
				for sibling in unlocked_achievements_container.get_children():
					var sibling_data = AchievementManager.achievements.get(sibling.achievement_id, null)
					var achievement_data = AchievementManager.achievements.get(achievement_id, null)

					if sibling_data.unlocked_date < achievement_data.unlocked_date:
						break
					index += 1
				

				unlocked_achievements_container.add_child(child)
				unlocked_achievements_container.move_child(child, index)
				break
		
	update_achievements_unlocked_percentage()

func _on_achievements_reset() -> void:
	_on_achievements_loaded()

	update_achievements_unlocked_percentage()
	achievement_notifier.clear_notifications()

var hidden_achievement_display

func _on_achievements_loaded() -> void:
	for i in unlocked_achievements_container.get_children():
		i.queue_free()
		
	for i in locked_achievements_container.get_children():
		i.queue_free()

	for i in hidden_achievements_container.get_children():
		i.queue_free()

	var sorted_ids = AchievementManager.achievements_list.keys()

	for achievement_id in sorted_ids:
		var achievement_display = ACHIEVEMENT_DISPLAY.instantiate()
		achievement_display.achievement_id = achievement_id

		var data = AchievementManager.achievements.get(achievement_id, null)
		if data == null or not data.unlocked:
			if AchievementManager.achievements_list.get(achievement_id).hidden:
				achievement_display.visible = false
				if !hidden_achievement_display:
					hidden_achievement_display = ACHIEVEMENT_DISPLAY.instantiate()
					locked_container.add_child(hidden_achievement_display)
				hidden_achievements_container.add_child(achievement_display)
				hidden_achievement_display.achievement_icon.texture = load("uid://cg3b84ak8bsrv")
				hidden_achievement_display.achievement_name.text = "Hidden Achievements"
				hidden_achievement_display.progress_container.visible = false
				hidden_achievement_display.achievement_action_label.visible = false
				update_hidden_achievements()
			else:
				locked_achievements_container.add_child(achievement_display)
		else:
			var unlocked_achievements = []
			for child in unlocked_achievements_container.get_children():
				unlocked_achievements.append(child)
			unlocked_achievements.sort_custom(func(a, b):
				var a_data = AchievementManager.achievements.get(a.achievement_id, null)
				var b_data = AchievementManager.achievements.get(b.achievement_id, null)

				return (b_data != null and b_data.unlocked_date) < (a_data != null and a_data.unlocked_date)
			)

			var index = 0
			for sibling in unlocked_achievements:
				var sibling_data = AchievementManager.achievements.get(sibling.achievement_id, null)
				var achievement_data = AchievementManager.achievements.get(achievement_id, null)
				if sibling_data.unlocked_date < achievement_data.unlocked_date:
					break
				index += 1

			unlocked_achievements_container.add_child(achievement_display)
			unlocked_achievements_container.move_child(achievement_display, index)
		
	update_achievements_unlocked_percentage()

func update_achievements_unlocked_percentage() -> void:
	if AchievementManager.unlocked_achievements_number == AchievementManager.achievements_number:
		achievements_unlocked_label.text = "You've unlocked all achievements! %s/%s" % [AchievementManager.unlocked_achievements_number, AchievementManager.achievements_number]
	else:
		achievements_unlocked_label.text = "%s of %s achievements unlocked" % [AchievementManager.unlocked_achievements_number, AchievementManager.achievements_number]
	var percent = float(AchievementManager.unlocked_achievements_number) / AchievementManager.achievements_number * 100.0
	achievements_unlocked_percentage.text = "(%.0f%%)" % [percent]
	achievements_progress_bar.max_value = AchievementManager.achievements_number
	achievements_progress_bar.value = AchievementManager.unlocked_achievements_number

func update_hidden_achievements():
	if hidden_achievement_display:
		hidden_achievement_display.achievement_description.text = "%d achievements are hidden." % int(hidden_achievements_container.get_child_count())
		if hidden_achievements_container.get_child_count() < 1:
			hidden_achievement_display.visible = false
		else:
			hidden_achievement_display.visible = true
	
func _process(_delta: float) -> void:
	if AchievementManager.achievements_number == 0 or AchievementManager.unlocked_achievements_number == AchievementManager.achievements_number:
		locked_container.visible = false
	else:
		locked_container.visible = true

	unlocked_container.visible = AchievementManager.unlocked_achievements_number > 0

	update_hidden_achievements()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			AchievementManager.unlock_achievement("press_space")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AchievementManager.progress_achievement("quintuple_click", 1)
