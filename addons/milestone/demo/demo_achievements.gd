extends Control

const AchievementDisplay = preload("uid://b2ygwvy3dv00a")

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
		for child in %HiddenAchievementContainer.get_children():
			if child.achievement_id == achievement_id:
				child.visible = true
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
	else:
		for child in %LockedAchievementContainer.get_children():
			if child.achievement_id == achievement_id:
				child.visible = true
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
	_on_achievements_loaded()

	update_achievements_unlocked_percentage()
	%AchievementNotifier.clear_notifications()

var hidden_achievement_display

func _on_achievements_loaded() -> void:
	for i in %UnlockedAchievementContainer.get_children():
		i.queue_free()
		
	for i in %LockedAchievementContainer.get_children():
		i.queue_free()

	for i in %HiddenAchievementContainer.get_children():
		i.queue_free()

	var sorted_ids = AchievementManager.achievements_list.keys()

	for achievement_id in sorted_ids:
		var achievement_display = AchievementDisplay.instantiate()
		achievement_display.achievement_id = achievement_id

		var data = AchievementManager.achievements.get(achievement_id, null)
		if data == null or not data.unlocked:
			if AchievementManager.achievements_list.get(achievement_id).hidden:
				achievement_display.visible = false
				if !hidden_achievement_display:
					hidden_achievement_display = AchievementDisplay.instantiate()
					%LockedContainer.add_child(hidden_achievement_display)
				%HiddenAchievementContainer.add_child(achievement_display)
				hidden_achievement_display.find_child("AchievementIcon").texture = load("uid://cg3b84ak8bsrv")
				hidden_achievement_display.find_child("AchievementName").text = "Hidden Achievements"
				hidden_achievement_display.find_child("ProgressContainer").visible = false
				hidden_achievement_display.find_child("AchievementActionLabel").visible = false
				update_hidden_achievements()
			else:
				%LockedAchievementContainer.add_child(achievement_display)
		else:
			var unlocked_achievements = []
			for child in %UnlockedAchievementContainer.get_children():
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

func update_hidden_achievements():
	if hidden_achievement_display:
		hidden_achievement_display.find_child("AchievementDescription").text = "%d achievements are hidden." % int(%HiddenAchievementContainer.get_child_count())
		if %HiddenAchievementContainer.get_child_count() < 1:
			hidden_achievement_display.visible = false
		else:
			hidden_achievement_display.visible = true
	
func _process(_delta: float) -> void:
	if AchievementManager.achievements_number == 0 or AchievementManager.unlocked_achievements_number == AchievementManager.achievements_number:
		%LockedContainer.visible = false
	else:
		%LockedContainer.visible = true

	%UnlockedContainer.visible = AchievementManager.unlocked_achievements_number > 0

	update_hidden_achievements()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			AchievementManager.unlock_achievement("press_space")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AchievementManager.progress_achievement("five_clicks", 1)
