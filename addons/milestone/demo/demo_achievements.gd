extends Control

const AchievementDisplay = preload("uid://b2ygwvy3dv00a")

func _ready() -> void:
	%ResetAchievements.pressed.connect(AchievementManager.reset_achievements)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.achievements_reset.connect(_on_achievements_reset)
	AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

	AchievementManager.progress_achievement("game_launch")

func _on_achievement_unlocked(achievement_id: String) -> void:
	for child in %LockedAchievementContainer.get_children():
		if child.achievement_id == achievement_id:
			child.get_parent().remove_child(child)

			var index = 0
			for sibling in %UnlockedAchievementContainer.get_children():
				var sibling_data = AchievementManager.achievements.get(sibling.achievement_id, null)
				var achievement_data = AchievementManager.achievements.get(achievement_id, null)

				if sibling_data.unlocked_date < achievement_data.unlocked_date:
					break
				index += 1

			%UnlockedAchievementContainer.add_child(child)
			%UnlockedAchievementContainer.move_child(child, index)
			break
	
	update_achievements_unlocked_percentage()

func _on_achievements_reset() -> void:
	for child in %UnlockedAchievementContainer.get_children():
		var achievement_id = child.achievement_id
		child.get_parent().remove_child(child)

		var index = 0
		for sibling in %LockedAchievementContainer.get_children():
			if achievement_id < sibling.achievement_id:
				break
			index += 1

		%LockedAchievementContainer.add_child(child)
		%LockedAchievementContainer.move_child(child, index)

	update_achievements_unlocked_percentage()

func _on_achievements_loaded() -> void:
	var sorted_ids = AchievementManager.achievements_list.keys()

	for achievement_id in sorted_ids:
		var achievement_display = AchievementDisplay.instantiate()
		achievement_display.achievement_id = achievement_id

		var data = AchievementManager.achievements.get(achievement_id, null)
		if data == null or not data.unlocked:
			%LockedAchievementContainer.add_child(achievement_display)
		else:
			var unlocked_achievements = []
			for child in %UnlockedAchievementContainer.get_children():
				var child_data = AchievementManager.achievements.get(child.achievement_id, null)
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

			%UnlockedAchievementContainer.add_child(achievement_display)
			%UnlockedAchievementContainer.move_child(achievement_display, index)
		
	update_achievements_unlocked_percentage()

func update_achievements_unlocked_percentage() -> void:
	if AchievementManager.unlocked_achievements_number == AchievementManager.achievements_number:
		%AchievementsUnlockedLabel.text = "You've unlocked all achievements! %s/%s" % [AchievementManager.unlocked_achievements_number, AchievementManager.achievements_number]
	else:
		%AchievementsUnlockedLabel.text = "%s of %s achievements unlocked" % [AchievementManager.unlocked_achievements_number, AchievementManager.achievements_number]
	var percent = float(AchievementManager.unlocked_achievements_number) / AchievementManager.achievements_number * 100.0
	%AchievementsUnlockedPercentage.text = "(%.0f%%)" % [percent]
	%AchievementsProgressBar.max_value = AchievementManager.achievements_number
	%AchievementsProgressBar.value = AchievementManager.unlocked_achievements_number

func _process(_delta: float) -> void:
	if AchievementManager.achievements_number == 0 or AchievementManager.unlocked_achievements_number == AchievementManager.achievements_number:
		%LockedContainer.visible = false
	else:
		%LockedContainer.visible = true

	%UnlockedContainer.visible = AchievementManager.unlocked_achievements_number > 0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			AchievementManager.progress_achievement("press_space")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AchievementManager.progress_achievement("five_clicks", 1)
