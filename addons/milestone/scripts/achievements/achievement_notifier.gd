@icon("uid://ctdctl2mfp36l")

## AchievementNotifier displays on-screen notifications when achievements are unlocked or their progress is updated.
## Useful for visually informing players about achievement milestones during gameplay.
class_name AchievementNotifier
extends Node

## Where the notification should be displayed at.
@export_enum("TopLeft", "TopRight", "BottomLeft", "BottomRight") var screen_corner := "BottomRight"


@export var user_interface : Node

## The notification scene to use.[br][br]
## [b]Note:[/b] Needs to be setup similarily to the [code]res://addons/milestone/components/achievement_notification.tscn[/code] file, you could as well edit that component to your liking.
@export var notification_component: PackedScene = preload("uid://dhdqvikxt7uvu")
## The animation duration.
@export var animation_duration: float = 0.2

# TODO: Add support for different animation types in the future. I barely slept coding this so it's very buggy at the moment.
# enum ANIMATION_TYPE {
# 	## Transition from left to right.
# 	LEFT_TO_RIGHT,
# 	## Transition from right to left.
# 	RIGHT_TO_LEFT,
# 	## Transition from top to bottom.
# 	TOP_TO_BOTTOM,
# 	## Transition from bottom to top.
# 	BOTTOM_TO_TOP,
# 	## Fade in and out.
# 	FADE,
# }
#
# ## The animation type of the notification.
# @export var in_animation_type: ANIMATION_TYPE = ANIMATION_TYPE.TOP_TO_BOTTOM
# ## The outro animation type of the notification.
# @export var out_animation_type: ANIMATION_TYPE = ANIMATION_TYPE.FADE

## The duration of how long the notification is visible on screen before it starts the outro animation.
@export var on_screen_duration: float = 5.0
## The max amount of notifications that can be stacked.
@export_range(1, 10) var max_stacked_notifications: int = 3
## The spacing between each notification.
@export var notification_spacing: int = 0
## The margin between the notification and the screen edge.
@export var margin: int = 0

@export_category("Achievement Sounds")
## The bus to play sounds on. Defaults to Master if can't be found.
@export var bus_name: String = "Master"
## The sound to play when unlocked. Can be empty.
@export var unlocked_sound: AudioStream = preload("uid://cnwln1wanowhk")
## The sound to play when progress is made. Can be empty.
@export var progress_sound: AudioStream = null
## The volume of the sounds.
@export_range(-5.0, 3.0) var volume: float = 0.5
## The pitch scale of the sounds.
@export var pitch_scale: float = 1.0

var _queue: Array = []
var _active_notifications: Array = []

# Tracks how many increments have happened per achievement.
var _progress_tracker: Dictionary = {}

# Stores the timer for each notification.
var _notification_timers: Dictionary = {}

# Stores all tweens for each notification. Only used for cleanup.
var _notification_tweens: Dictionary = {}

var start_pos

func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.achievement_progressed.connect(_on_achievement_progressed)
	get_viewport().size_changed.connect(_update_notification_positions)

func _on_achievement_unlocked(achievement_id: String) -> void:
	if unlocked_sound:
		play_sfx(unlocked_sound)

	if _progress_tracker.has(achievement_id):
		_progress_tracker[achievement_id] = 0

	if _is_notification_already_displayed(achievement_id):
		var notif = _get_notification_by_id(achievement_id)
		if notif:
			notif.update_achievement_display(achievement_id, "progress")
			var timer = _notification_timers.get(notif.id)
			if timer:
				timer.stop()
				timer.start()
		return

	var data = {"id": achievement_id, "type": "unlock"}
	_queue.push_back(data)
	_process_queue(data["type"])

func _on_achievement_progressed(achievement_id: String, _progress_amount: int) -> void:
	if not _progress_tracker.has(achievement_id):
		_progress_tracker[achievement_id] = 0
	
	_progress_tracker[achievement_id] += _progress_amount

	var achievement = AchievementManager.get_achievement(achievement_id)
	var achievement_resource = AchievementManager.get_achievement_resource(achievement_id)
	if _progress_tracker[achievement_id] % achievement_resource.indicate_progress_interval == 0 and not achievement.unlocked and not achievement_resource.hidden:
		if _is_notification_already_displayed(achievement_id):
			var notif = _get_notification_by_id(achievement_id)
			if notif:
				notif.update_achievement_display(achievement_id, "progress")
				var timer = _notification_timers.get(notif.id)
				if timer:
					timer.stop()
					timer.start()
			return

		var data = {"id": achievement_id, "type": "progress"}
		_queue.push_back(data)
		_process_queue(data["type"])

		if progress_sound:
			play_sfx(progress_sound)

func _process_queue(type: String) -> void:
	if _queue.is_empty() or _active_notifications.size() >= max_stacked_notifications:
		await get_tree().create_timer(0.5).timeout
		_process_queue(type)
		return
	
	var data = _queue.pop_front()
	var achievement_notification = notification_component.instantiate()
	
	if achievement_notification.has_method("update_achievement_display"):
		achievement_notification.id = data.id
		achievement_notification.update_achievement_display(data.id, type)

	show_notification(achievement_notification)
	

func _is_notification_already_displayed(achievement_id: String) -> bool:
	for notif in _active_notifications:
		if notif.id == achievement_id:
			return true
	
	for queued in _queue:
		if queued["id"] == achievement_id:
			return true
	
	return false

var player: AudioStreamPlayer

func play_sfx(stream: AudioStream) -> void:
	if player:
		return
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(clamp(volume, -5.0, 3.0))
	player.pitch_scale = pitch_scale

	if AudioServer.get_bus_index(bus_name) == -1:
		player.bus = "Master"
	else:
		player.bus = bus_name

	player.autoplay = false
	player.finished.connect(player.queue_free)
	
	if user_interface:
		user_interface.add_child(player)
	else:
		add_child(player)
	player.play()

func show_notification(_notification: Control) -> void:
	if user_interface:
		user_interface.add_child(_notification)
	else:
		add_child(_notification)
	_active_notifications.insert(0, _notification)

	start_pos = _get_offscreen_position_from_type(_notification)
	_notification.position = start_pos

	var target_pos: Vector2 = _get_target_position(_notification)

	_notification.z_index += _active_notifications.size()

	
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)
	_notification_tweens[_notification.id] = tween
	tween.tween_property(_notification, "position", target_pos, animation_duration)

	tween.finished.connect(func():
		if _notification:
			_notification.z_index -= _active_notifications.size()
	)

	_update_notification_positions()

	var timer = Timer.new()
	timer.wait_time = on_screen_duration
	timer.one_shot = true
	timer.autostart = true
	_notification.add_child(timer)

	_notification_timers[_notification.id] = timer

	await timer.timeout
	_notification_timers.erase(_notification.id)
	_active_notifications.erase(_notification)

	tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(_notification, "position", start_pos, animation_duration)

	tween.finished.connect(func():
		if _notification and _notification.is_inside_tree():
			_notification.queue_free()

		if _active_notifications.size() > 0 and is_instance_valid(_notification):
			_update_notification_positions()
	)

func _get_target_position(_notification: Control) -> Vector2:
	var corner_pos = _get_corner_position()
	var offset = Vector2()

	match screen_corner:
		"TopLeft":
			offset = Vector2(0, _notification.size.y)
		"TopRight":
			offset = Vector2(-_notification.size.x, _notification.size.y)
		"BottomLeft":
			offset = Vector2(0, -_notification.size.y)
		"BottomRight":
			offset = Vector2(-_notification.size.x - margin, -_notification.size.y - margin)
		_:
			offset = Vector2(0, 0)

	return corner_pos + offset

func _get_corner_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size

	match screen_corner:
		"TopLeft":
			return Vector2(0, 0)
		"TopRight":
			return Vector2(screen_size.x, 0)
		"BottomLeft":
			return Vector2(0, screen_size.y)
		"BottomRight":
			return Vector2(screen_size.x, screen_size.y)
		_:
			return Vector2(0, 0)

func _get_offscreen_position_from_type(_notification: Control) -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	
	# TODO: Add support for different animation types in the future. I barely slept coding this so it's very buggy at the moment.
	# match in_animation_type:
	# 	ANIMATION_TYPE.TOP_TO_BOTTOM:
	# 		return Vector2(_get_corner_position().x - _notification.size.x, -_notification.size.y - margin)
	# 	ANIMATION_TYPE.BOTTOM_TO_TOP:
	# 		return Vector2(_get_corner_position().x - _notification.size.x - margin, screen_size.y)
	# 	ANIMATION_TYPE.LEFT_TO_RIGHT:
	# 		return Vector2(-_notification.size.x - margin, _get_corner_position().y)
	# 	ANIMATION_TYPE.RIGHT_TO_LEFT:
	# 		return Vector2(screen_size.x + margin, _get_corner_position().y)

	match screen_corner:
		"TopLeft":
			return Vector2(0 + margin, -_notification.size.y + margin)
		"TopRight":
			return Vector2(_get_corner_position().x - _notification.size.x - margin, -_notification.size.y - margin)
		"BottomLeft":
			return Vector2(0 + margin, screen_size.y + margin)
		"BottomRight":
			return Vector2(_get_corner_position().x - _notification.size.x - margin, screen_size.y - margin)
		_:
			return Vector2(0, 0)


# TODO: Rewrite the notification stacking. 
func _update_notification_positions():
	var base_pos = _get_corner_position()
	var current_offset = Vector2()

	if _active_notifications.size() == 0:
		return

	if is_instance_valid(_active_notifications[0]) == false:
		return
	
	match screen_corner:
		"BottomRight":
			current_offset = Vector2(-_active_notifications[0].size.x - margin, -_active_notifications[0].size.y - margin)
		"BottomLeft":
			current_offset = Vector2(margin, -_active_notifications[0].size.y - margin)
		"TopRight":
			current_offset = Vector2(-_active_notifications[0].size.x - margin, margin)
		"TopLeft":
			current_offset = Vector2(margin, margin)

	start_pos = _get_offscreen_position_from_type(_active_notifications[0])

	for i in range(_active_notifications.size()):
		var notif = _active_notifications[i]
		if not is_instance_valid(notif):
			continue

		var pos = base_pos + current_offset
		
		_notification_tweens[i] = create_tween()

		_notification_tweens[i].tween_property(notif, "position", pos, animation_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)

		match screen_corner:
			"BottomRight", "BottomLeft":
				current_offset.y -= notif.size.y + notification_spacing
			"TopRight", "TopLeft":
				current_offset.y += notif.size.y + notification_spacing


func _get_notification_by_id(achievement_id: String) -> Node:
	for notif in _active_notifications:
		if notif.id == achievement_id:
			return notif
	return null

func clear_notifications() -> void:
	for notif in _active_notifications:
		_notification_timers[notif.id].stop()
		_notification_timers[notif.id].emit_signal("timeout")
		_notification_tweens[notif.id].kill()
		notif.queue_free()
		
	_active_notifications.clear()
	_queue.clear()
	_notification_timers.clear()

func _exit_tree() -> void:
	clear_notifications()
