extends Control

func _ready() -> void:
	await AchievementManager.achievements_loaded
	AchievementManager.unlock_all_achievements()
