extends Control

func _ready() -> void:
	AchievementManager.progress_achievement("game_launch")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			AchievementManager.progress_achievement("press_space")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AchievementManager.progress_achievement("five_clicks", 1)
