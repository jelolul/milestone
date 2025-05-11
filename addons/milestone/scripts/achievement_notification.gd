@tool
extends Control

enum ANIMATION_TYPE {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	TOP_TO_BOTTOM,
	BOTTOM_TO_TOP,
	FADE,
}

## The animation type of the notification.
var animation_type: ANIMATION_TYPE = ANIMATION_TYPE.TOP_TO_BOTTOM
## The outro animation type of the notification.
var outro_animation_type: ANIMATION_TYPE = ANIMATION_TYPE.FADE
## The duration of the notification on screen.
var on_screen_duration: float = 5.0

## The sound to play when unlocked.
var unlocked_sound: AudioStream = preload("../assets/achievement_unlocked.wav")
## The sound to play when progress is made.
var progress_sound: AudioStream = null
## The volume of the sounds.
var volume: float = 0.5
## The pitch scale of the sounds.
var pitch_scale: float = 1.0
## The bus to play sounds on.
var bus_name: String = "Master"

## Whether to show the unlocked icon next to the achievement action.
var show_unlocked_icon: bool = true

var id: String = ""
var current_timer: Timer = null
var is_animating := false
var notification_shown := false

# Tracks how many increments have happened
var progress_tracker: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if not id.is_empty():
		self.name = id
		
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String) -> void:
	if id == achievement_id:
		update_achievement_display(achievement_id, "unlock")

func _on_achievement_progressed(achievement_id: String, _progress_amount: int) -> void:
	if id == achievement_id:
		update_achievement_display(achievement_id, "progress")
		progress_tracker += 1

func update_achievement_display(achievement_id: String, display_type: String = "progress") -> void:
	var achievement_resource: Achievement = AchievementManager.get_achievement_resource(achievement_id)
	var achievement: Dictionary = AchievementManager.get_achievement(achievement_id)

	%AchievementName.text = achievement_resource.name

	%AchievementIcon.texture_filter = achievement_resource.icon_filter
	%AchievementIcon.texture = achievement_resource.icon

	%ProgressContainer.visible = achievement_resource.progressive

	if achievement_resource.progressive:
		%AchievementProgressBar.value = achievement.progress
		%AchievementProgressBar.max_value = achievement_resource.progress_goal
		%AchievementProgressLabel.text = "(%s/%s)" % [int(achievement.progress), achievement_resource.progress_goal]

	%AchievementBadge.visible = false

	if display_type == "unlock":
		%AchievementActionLabel.text = "Achievement Unlocked!"
		%AchievementBadge.visible = true
		
		%AchievementRareOverlay.visible = achievement_resource.considered_rare
		%AchievementProgressBar.visible = false

	elif display_type == "progress":
		%AchievementActionLabel.text = "Achievement Progress"

		%AchievementRareOverlay.visible = false
		%AchievementProgressBar.visible = true

	if achievement.unlocked:
		%AchievementIcon.material.set_shader_parameter("use_grayscale", false)
	else:
		if not achievement_resource.unachieved_icon:
			%AchievementIcon.material.set_shader_parameter("use_grayscale", true)
		else:
			%AchievementIcon.texture = achievement_resource.unachieved_icon