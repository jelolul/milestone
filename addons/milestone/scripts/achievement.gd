@tool
@icon("res://addons/milestone/assets/icon.svg")
class_name Achievement
extends Resource

# General

## The ID of the achievement used when unlocking/progressing. Must be unique from other achievements, and be the same as the file name.
@export var id: String = "achievement_id"
## The icon of the achievement.
@export var icon: Texture2D = preload("res://addons/milestone/assets/missing_icon.svg")
## The filter the icon should use.
@export var icon_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
## The unachieved icon (optional).
@export var unachieved_icon: Texture2D
## The hidden icon of the achievement.
@export var hidden_icon: Texture2D = preload("res://addons/milestone/assets/hidden_achievement.svg")
## Name of the achievement.
@export var name: String = "Achievement Name"
## Description of the achievement.
@export var description: String = "Achievement Description"
## Is the achievement hidden/a secret?
@export var hidden: bool = false
## Is the achievement considered rare?
@export var considered_rare: bool = false

## Progression

## Whether the achievement is progressive or not.
@export var progressive: bool = false
## The progress goal of the achievement.
@export var progress_goal: int = 0