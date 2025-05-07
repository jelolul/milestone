extends Node

var achievements_list: Array = []

## How many achievements are available.
var achievements_number: int = 0

var achievements: Dictionary = {}

signal achievement_unlocked(achievement_id)
signal achievement_progressed(achievement_id, progress_amount)

func _ready() -> void:
	achievements_list = get_achievements()
	achievements_number = achievements_list.size()

func get_achievement_resource(achievement_id: String) -> Achievement:
	var achievement: Achievement = load(ProjectSettings.get_setting("milestone/general/achievements_path") + achievement_id + ".tres")

	if achievement:
		return achievement
	else:
		return null

func progress_achievement(achievement_id: String, progress_amount: int = 1) -> void:
	var achievement: Achievement = get_achievement_resource(achievement_id)
	if achievement:
		if not achievements.has(achievement_id):
			achievements[achievement_id] = {
				"unlocked": false,
				"unlocked_date": 0,
				"progress": 0,
			}
		if achievements[achievement_id]["unlocked"] == false:
			if achievement.progressive:
				achievements[achievement_id]["progress"] = min(achievements[achievement_id]["progress"] + progress_amount, achievement.progress_goal)
				if achievements[achievement_id]["progress"] >= achievement.progress_goal:
					achievements[achievement_id]["unlocked"] = true
					achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()
					if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
						print("[Milestone] Achievement %s was unlocked!" % achievement_id)
					emit_signal("achievement_unlocked", achievement_id)
				else:
					if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
						print("[Milestone] Achievement %s progressed to (%s/%s)!" % [achievement_id, achievements[achievement_id]["progress"], achievement.progress_goal])
					emit_signal("achievement_progressed", achievement_id, progress_amount)
			else:
				achievements[achievement_id]["unlocked"] = true
				achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()
				if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
					print("[Milestone] Achievement %s was unlocked!" % achievement_id)
				emit_signal("achievement_unlocked", achievement_id)
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print("[Milestone] Could not find achievement with ID %s" % achievement_id)

func get_achievement(achievement_id: String) -> Dictionary:
	return achievements[achievement_id]

# TODO: Implement a function that resets all achievements.
func reset_achievements() -> void:
	pass

# TODO: Implement a function that clears a specific achievement.
func achievement_clear(achievement_id) -> void:
	pass

func get_achievements() -> Array:
	var _achievements = []
	var dir = DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))
	if dir == OK:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.extension() == "tres" or file.extension() == "res":
				var resource = load(ProjectSettings.get_setting("milestone/general/achievements_path") + file)
				if resource is Achievement:
					_achievements.append(resource)
			file = dir.get_next()
		dir.list_dir_end()
	return _achievements