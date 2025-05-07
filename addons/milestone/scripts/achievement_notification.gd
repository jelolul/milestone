extends Control

enum ANIMATION_TYPE {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	TOP_TO_BOTTOM,
	BOTTOM_TO_TOP,
	FADE,
}

## The animation type of the notification.
@export var animation_type: ANIMATION_TYPE = ANIMATION_TYPE.TOP_TO_BOTTOM
## The outro animation type of the notification.
@export var outro_animation_type: ANIMATION_TYPE = ANIMATION_TYPE.FADE
## The duration of the notification on screen.
@export var on_screen_duration: float = 5.0

## The sound to play when unlocked.
@export var unlocked_sound: AudioStream = preload("../assets/achievement_unlocked.wav")
## The sound to play when progress is made.
@export var progress_sound: AudioStream = null
## The volume of the sounds.
@export_range(-5.0, 3.0) var volume: float = 0.5
## The pitch scale of the sounds.
@export var pitch_scale: float = 1.0
## The bus to play sounds on.
@export var bus_name: String = "Master"

var achievements_queue: Array[Dictionary] = []
var showing_notification := false
var current_displayed_id := ""
var current_timer: Timer = null
var is_animating := false
var notification_shown := false

func _ready() -> void:
	self.visible = false
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.achievement_progressed.connect(_on_achievement_progressed)

func _on_achievement_unlocked(achievement_id: String) -> void:
	if showing_notification and current_displayed_id == achievement_id:
		update_achievement_display(achievement_id, "unlock")

		if current_timer:
			current_timer.start(on_screen_duration)

		achievements_queue = achievements_queue.filter(func(item):
			return item["id"] != achievement_id
		)
		return

	achievements_queue = achievements_queue.filter(func(item):
		return item["id"] != achievement_id
	)

	enqueue_achievement("unlock", achievement_id)

func _on_achievement_progressed(achievement_id: String, _progress_amount: int) -> void:
	var achievement_resource: Achievement = AchievementManager.get_achievement_resource(achievement_id)
	if achievement_resource.hidden:
		return

	if achievement_resource.progressive:
		if showing_notification and current_displayed_id == achievement_id:
			update_achievement_display(achievement_id, "progress")

			if current_timer:
				current_timer.start(on_screen_duration)

			achievements_queue = achievements_queue.filter(func(item):
				return item["id"] != achievement_id
			)
			return

		achievements_queue = achievements_queue.filter(func(item):
			return !(item["type"] == "progress" and item["id"] == achievement_id)
		)

	enqueue_achievement("progress", achievement_id)

func enqueue_achievement(type: String, id: String) -> void:
	achievements_queue.append({"type": type, "id": id})
	if not showing_notification:
		process_next_notification()

func process_next_notification() -> void:
	if achievements_queue.is_empty():
		showing_notification = false
		current_displayed_id = ""
		return

	var next = achievements_queue.pop_front()
	current_displayed_id = next["id"]
	showing_notification = true
	notification_shown = false

	update_achievement_display(next["id"], next["type"])

	if current_timer:
		current_timer.queue_free()

	current_timer = Timer.new()
	current_timer.one_shot = true
	current_timer.wait_time = on_screen_duration
	current_timer.timeout.connect(func():
		await hide_notification(self, outro_animation_type)
		showing_notification = false
		process_next_notification()
	)

	add_child(current_timer)
	current_timer.start()

func update_achievement_display(achievement_id: String, display_type: String) -> void:
	var achievement_resource: Achievement = AchievementManager.get_achievement_resource(achievement_id)
	var achievement: Dictionary = AchievementManager.get_achievement(achievement_id)

	if not notification_shown:
		show_notification(self, animation_type)
		notification_shown = true

	%AchievementName.text = achievement_resource.name

	%AchievementIcon.texture_filter = achievement_resource.icon_filter
	%AchievementIcon.texture = achievement_resource.icon

	%ProgressContainer.visible = achievement_resource.progressive

	if achievement_resource.progressive:
		%AchievementProgressBar.value = achievement.progress
		%AchievementProgressBar.max_value = achievement_resource.progress_goal
		%AchievementProgressLabel.text = "(%s/%s)" % [int(achievement.progress), achievement_resource.progress_goal]

	if display_type == "unlock":
		%AchievementActionLabel.text = "Achievement Unlocked!"
		
		%AchievementRareOverlay.visible = achievement_resource.considered_rare

		if unlocked_sound:
			play_sfx(unlocked_sound)

	elif display_type == "progress":
		%AchievementActionLabel.text = "Achievement Progress"

		%AchievementRareOverlay.visible = false

		if progress_sound:
			play_sfx(progress_sound)

	if achievement.unlocked:
		%AchievementIcon.material.set_shader_parameter("use_grayscale", false)
	else:
		if not achievement_resource.unachieved_icon:
			%AchievementIcon.material.set_shader_parameter("use_grayscale", true)
		else:
			%AchievementIcon.texture = achievement_resource.unachieved_icon

func play_sfx(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(clamp(volume, -5.0, 3.0))
	player.pitch_scale = pitch_scale

	if AudioServer.get_bus_index(bus_name) == -1:
		player.bus = "Master"
	else:
		player.bus = bus_name

	player.autoplay = false
	player.finished.connect(player.queue_free)
	
	add_child(player)
	player.play()

var tween

func show_notification(node: Control, animation_type: ANIMATION_TYPE, duration: float = 0.4) -> void:
	node.visible = true
	if tween and tween.is_running():
		return

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	match animation_type:
		ANIMATION_TYPE.LEFT_TO_RIGHT:
			node.modulate.a = 1.0
			node.position.x = - node.size.x
			tween.tween_property(node, "position:x", 0, duration)

		ANIMATION_TYPE.RIGHT_TO_LEFT:
			node.modulate.a = 1.0
			node.position.x = get_viewport_rect().size.x
			tween.tween_property(node, "position:x", 0, duration)

		ANIMATION_TYPE.TOP_TO_BOTTOM:
			node.modulate.a = 1.0
			node.position.y = - node.size.y
			tween.tween_property(node, "position:y", 0, duration)

		ANIMATION_TYPE.BOTTOM_TO_TOP:
			node.modulate.a = 1.0
			node.position.y = get_viewport_rect().size.y
			tween.tween_property(node, "position:y", 0, duration)

		ANIMATION_TYPE.FADE:
			node.modulate.a = 0.0
			tween.tween_property(node, "modulate:a", 1.0, duration)

func hide_notification(node: Control, animation_type: ANIMATION_TYPE, duration: float = 0.4) -> void:
	if tween and tween.is_running():
		return
		
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	match animation_type:
		ANIMATION_TYPE.LEFT_TO_RIGHT:
			tween.tween_property(node, "position:x", get_viewport_rect().size.x, duration)

		ANIMATION_TYPE.RIGHT_TO_LEFT:
			tween.tween_property(node, "position:x", -node.size.x, duration)

		ANIMATION_TYPE.TOP_TO_BOTTOM:
			tween.tween_property(node, "position:y", get_viewport_rect().size.y, duration)

		ANIMATION_TYPE.BOTTOM_TO_TOP:
			tween.tween_property(node, "position:y", -node.size.y, duration)

		ANIMATION_TYPE.FADE:
			tween.tween_property(node, "modulate:a", 0.0, duration)

	await tween.finished
	node.visible = false
	notification_shown = false
