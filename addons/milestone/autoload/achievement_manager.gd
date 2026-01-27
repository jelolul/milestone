extends Node

## The achievements available in the game.
var achievements_list: Dictionary = {}

## How many achievements are available.
var achievements_number: int = 0

## How many hidden achievements are available.
var hidden_achievements_number: int = 0

## How many achievements are unlocked.
var unlocked_achievements_number: int = 0:
	get:
		unlocked_achievements_number = get_unlocked_achievements().size()
		return unlocked_achievements_number

## The achievements the player has unlocked/progressed.
var achievements: Dictionary = {}

signal achievement_unlocked(achievement_id)
signal achievement_progressed(achievement_id, progress_amount)
signal achievement_reset(achievement_id)

signal achievements_reset
signal achievements_loaded

func _ready() -> void:
	load_achievements()
	achievements_list = get_achievements()
	achievements_number = achievements_list.size()
	hidden_achievements_number = get_hidden_achievements().size()

	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print_rich("[b][MILESTONE][/b] Loaded achievements: %s" % achievements_number)

func get_achievement_resource(achievement_id: String) -> Achievement:
	var path = ProjectSettings.get_setting("milestone/general/achievements_path").path_join(achievement_id + ".tres")
	var achievement = load(path)

	if achievement is Achievement:
		return achievement
	else:
		return null


## Unlocks the achievement with the given ID.
func unlock_achievement(achievement_id: String, save_on_unlock: bool = true) -> void:
	var achievement: Achievement = get_achievement_resource(achievement_id)
	if achievement:
		if not achievements.has(achievement_id):
			achievements[achievement_id] = {
				"unlocked": false,
				"unlocked_date": 0,
				"progress": 0,
			}
		if achievements[achievement_id]["unlocked"] == false:
			achievements[achievement_id]["progress"] = achievement.progress_goal
			achievements[achievement_id]["unlocked"] = true
			achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()

			emit_signal("achievement_unlocked", achievement_id)

			if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
				print_rich("[b][MILESTONE][/b] Unlocked achievement: [code]%s[/code]" % achievement_id)
				print_rich("[b][MILESTONE][/b] Unlocked [b]%s/%s[/b] achievements" % [unlocked_achievements_number, achievements_number])
		if save_on_unlock:
			save_achievements()
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			push_error("[MILESTONE] Could not find achievement with ID [code]%s[/code]" % achievement_id)

## Progresses the achievement with the given ID using the specified progress amount.
func progress_achievement(achievement_id: String, progress_amount: int = 1) -> void:
	var achievement: Achievement = get_achievement_resource(achievement_id)
	if achievement:
		if not achievements.has(achievement_id):
			achievements[achievement_id] = {
				"unlocked": false,
				"unlocked_date": 0,
				"progress": 0,
			}

		if achievements[achievement_id]["unlocked"]:
			return

		if achievement.progressive:
			achievements[achievement_id]["progress"] = int(min(achievements[achievement_id]["progress"] + progress_amount, achievement.progress_goal))

			if achievements[achievement_id]["progress"] >= achievement.progress_goal:
				achievements[achievement_id]["unlocked"] = true
				achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()

				emit_signal("achievement_unlocked", achievement_id)

				if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
					print_rich("[b][MILESTONE][/b] Unlocked achievement: [code]%s[/code] (%s/%s)" % [achievement_id, achievements[achievement_id]["progress"], achievement.progress_goal])
					print_rich("[b][MILESTONE][/b] Unlocked [b]%s/%s[/b] achievements" % [unlocked_achievements_number, achievements_number])
			else:
				emit_signal("achievement_progressed", achievement_id, progress_amount)

				if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
					print_rich("[b][MILESTONE][/b] Achievement [code]%s[/code] progressed (%s/%s)" % [achievement_id, achievements[achievement_id]["progress"], achievement.progress_goal])
		else:
			achievements[achievement_id]["unlocked"] = true
			achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()

			emit_signal("achievement_unlocked", achievement_id)

			if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
				print_rich("[b][MILESTONE][/b] Unlocked achievement: [code]%s[/code]" % achievement_id)
				print_rich("[b][MILESTONE][/b] Unlocked [b]%s/%s[/b] achievements" % [unlocked_achievements_number, achievements_number])
		save_achievements()
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			push_error("[MILESTONE] Could not find achievement with ID [code]%s[/code]" % achievement_id)

## Progresses all achievements in the specified group by the given amount.
func progress_group(group_id: String, amount: int = 1) -> void:
	for achievement_id in achievements_list.keys():
		var achievement_res: Achievement = get_achievement_resource(achievement_id)
		if achievement_res and achievement_res.group == group_id and not is_unlocked(achievement_id):
			progress_achievement(achievement_id, amount)
	
## Returns an achievement dictionary.
func get_achievement(achievement_id: String) -> Dictionary:
	if not achievements.has(achievement_id) and achievements_list.has(achievement_id):
		achievements[achievement_id] = {
			"unlocked": false,
			"unlocked_date": 0,
			"progress": 0,
		}
		return achievements[achievement_id]
	elif achievements.has(achievement_id) and achievements_list.has(achievement_id):
		return achievements[achievement_id]
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print_rich("[b][MILESTONE][/b] Couldn't find an achievement with the ID: [code]%s[/code]" % achievement_id)
		return {}
	
## Returns an array of achievement resources belonging to the given group.
func get_achievements_by_group(group_id: String) -> Array:
	var group_achievements: Array = []

	for achievement_id in achievements_list.keys():
		var achievement_res: Achievement = get_achievement_resource(achievement_id)
		if achievement_res.group:
			if achievement_res and achievement_res.group == group_id:
				group_achievements.append(achievement_res)

	if group_achievements.is_empty():
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print_rich("[b][MILESTONE][/b] Couldn't find achievements in the group: [code]%s[/code]" % group_id)

	return group_achievements
	
## Resets all achievements.
func reset_achievements() -> void:
	if achievements.is_empty():
		return
	achievements.clear()
	save_achievements()
	emit_signal("achievements_reset")
	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print_rich("[b][MILESTONE][/b] All achievement progress was reset")

## Unlocks all achievements.
func unlock_all_achievements() -> void:
	for i in achievements_list:
		unlock_achievement(i, false)
	
	save_achievements()

## Returns true if the achievement is unlocked.
func is_unlocked(achievement_id: String) -> bool:
	if achievements.has(achievement_id):
		return achievements[achievement_id]["unlocked"]
	else:
		return false

## Returns the progress of the achievement.
func get_progress(achievement_id: String) -> int:
	if achievements.has(achievement_id) and achievements_list.has(achievement_id):
		return achievements[achievement_id].progress
	elif !achievements.has(achievement_id) and achievements_list.has(achievement_id):
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print_rich("[b][MILESTONE][/b] Couldn't find an achievement with the ID: [code]%s[/code]" % achievement_id)
		return 0
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print_rich("[b][MILESTONE][/b] Couldn't find an achievement with the ID: [code]%s[/code]" % achievement_id)
		return 0

func reset_achievement(achievement_id) -> void:
	achievements.erase(achievement_id)
	save_achievements()
	emit_signal("achievement_reset", achievement_id)
	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print_rich("[b][MILESTONE][/b] Removed achievement progress from: [code]%s[/code]" % achievement_id)

func get_unlocked_achievements() -> Dictionary:
	var _achievements: Dictionary = {}
	for achievement_id in achievements:
		if achievements[achievement_id]["unlocked"]:
			_achievements[achievement_id] = achievements[achievement_id]
	return _achievements

func get_hidden_achievements() -> Dictionary:
	var _achievements: Dictionary = {}
	for achievement_id in achievements_list:
		if achievements_list[achievement_id]["hidden"]:
			_achievements[achievement_id] = achievements_list[achievement_id]
	return _achievements

func get_achievements() -> Dictionary:
	var _achievements: Dictionary = {}
	var dir = DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.replace(".remap", "").get_extension() == "tres" or file.replace(".remap", "").get_extension() == "res":
				var resource = load(ProjectSettings.get_setting("milestone/general/achievements_path").path_join(file.replace(".remap", "")))
				if resource is Achievement:
					_achievements[resource.id] = resource
			file = dir.get_next()
		dir.list_dir_end()
	return _achievements

## Saves all achievements to user://achievements.json. It's recommended to encrypt achievements if you don't want an average user to be able to modify them.
func save_achievements() -> void:
	if ProjectSettings.get_setting("milestone/general/save_as_json", true) == true:
		var file = FileAccess.open("user://achievements.json", FileAccess.WRITE)
		file.store_string(JSON.stringify((achievements), "\t"))
		file.close()


## Loads all achievements from user://achievements.json. It's recommended to encrypt achievements if you don't want an average user to be able to modify them.
func load_achievements() -> void:
	if ProjectSettings.get_setting("milestone/general/save_as_json", true) == true:
		if FileAccess.file_exists("user://achievements.json"):
			var file = FileAccess.open("user://achievements.json", FileAccess.READ)
			if file:
				var json = file.get_as_text()
				file.close()
				if json:
					achievements = JSON.parse_string(json)
					achievements_loaded.emit.call_deferred()
