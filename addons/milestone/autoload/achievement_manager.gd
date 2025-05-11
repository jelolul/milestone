extends Node

## The achievements available in the game.
var achievements_list: Dictionary = {}

## How many achievements are available.
var achievements_number: int = 0

## How many achievements are unlocked.
var unlocked_achievements_number: int = 0:
	get:
		unlocked_achievements_number = get_unlocked_achievements().size()
		return unlocked_achievements_number

## The achievements the player has unlocked.
var achievements: Dictionary = {}

signal achievement_unlocked(achievement_id)
signal achievement_progressed(achievement_id, progress_amount)
signal achievement_cleared(achievement_id)

signal achievements_reset
signal achievements_loaded

func _ready() -> void:
	load_achievements()
	achievement_unlocked.connect(_on_achievement_unlocked)
	achievements_reset.connect(_on_achievement_unlocked.bind(""))
	achievements_loaded.connect(_on_achievement_unlocked.bind(""))
	achievements_list = get_achievements()
	achievements_number = achievements_list.size()

	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print("[Milestone] Loaded %s achievements!" % achievements_number)

func _on_achievement_unlocked(_achievement_id: String) -> void:
	unlocked_achievements_number = get_unlocked_achievements().size()

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
				achievements[achievement_id]["progress"] = int(min(achievements[achievement_id]["progress"] + progress_amount, achievement.progress_goal))

				if achievements[achievement_id]["progress"] >= achievement.progress_goal:
					achievements[achievement_id]["unlocked"] = true
					achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()

					emit_signal("achievement_unlocked", achievement_id)

					if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
						print("[Milestone] Achievement '%s' was unlocked! (%s/%s)" % [achievement_id, achievements[achievement_id]["progress"], achievement.progress_goal])
						print("[Milestone] Unlocked %s/%s achievements" % [unlocked_achievements_number, achievements_number])
				else:
					emit_signal("achievement_progressed", achievement_id, progress_amount)

					if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
						print("[Milestone] Achievement '%s' progressed to (%s/%s)" % [achievement_id, achievements[achievement_id]["progress"], achievement.progress_goal])
			else:
				achievements[achievement_id]["unlocked"] = true
				achievements[achievement_id]["unlocked_date"] = Time.get_unix_time_from_system()

				emit_signal("achievement_unlocked", achievement_id)

				if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
					print("[Milestone] Achievement '%s' was unlocked!" % achievement_id)
					print("[Milestone] Unlocked %s/%s achievements" % [unlocked_achievements_number, achievements_number])
		save_achievements()
	else:
		if ProjectSettings.get_setting("milestone/debug/print_errors") == true and OS.is_debug_build():
			print("[Milestone] Could not find achievement with ID '%s'" % achievement_id)

func get_achievement(achievement_id: String) -> Dictionary:
	if not achievements.has(achievement_id):
		achievements[achievement_id] = {
			"unlocked": false,
			"unlocked_date": 0,
			"progress": 0,
		}
	return achievements[achievement_id]

# TODO: Implement a function that resets all achievements.
func reset_achievements() -> void:
	achievements.clear()
	save_achievements()
	emit_signal("achievements_reset")
	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print("[Milestone] Reset all achievements!")

# TODO: Implement a function that clears a specific achievement.
func achievement_clear(achievement_id) -> void:
	achievements.erase(achievement_id)
	save_achievements()
	emit_signal("achievement_cleared", achievement_id)
	if ProjectSettings.get_setting("milestone/debug/print_output") == true and OS.is_debug_build():
		print("[Milestone] Cleared achievement %s!" % achievement_id)

func get_unlocked_achievements() -> Dictionary:
	var _achievements: Dictionary = {}
	for achievement_id in achievements:
		if achievements[achievement_id]["unlocked"]:
			_achievements[achievement_id] = achievements[achievement_id]
	return _achievements

func get_achievements() -> Dictionary:
	var _achievements: Dictionary = {}
	var dir = DirAccess.open(ProjectSettings.get_setting("milestone/general/achievements_path"))
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.get_extension() == "tres" or file.get_extension() == "res":
				var resource = load(ProjectSettings.get_setting("milestone/general/achievements_path") + file)
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
		var file = FileAccess.open("user://achievements.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			if json:
				achievements = JSON.parse_string(json)
				achievements_loaded.emit.call_deferred()
