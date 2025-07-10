class_name Achievement
extends Resource

# General

## The ID of the achievement used when unlocking/progressing. Must be unique from other achievements, and be the same as the file name. Use the Milestone workspace to change it.
@export var id: String = "achievement_id"
## The icon of the achievement.
@export var icon: Texture2D = preload("uid://dmbey47vfsa2g")
## The filter the icon should use.
@export var icon_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
## The unachieved icon (optional).
@export var unachieved_icon: Texture2D
## The hidden icon of the achievement.
@export var hidden_icon: Texture2D = preload("uid://cg3b84ak8bsrv")
## Name of the achievement.
@export var name: String = "Achievement Name"
## Description of the achievement.
@export var description: String = "Achievement Description"
## Is the achievement hidden/a secret?
@export var hidden: bool = false
## Is the achievement considered rare? If true, adds a glow around the border once unlocked.
@export var considered_rare: bool = false

## Progression

## Whether the achievement is progressive or not.
@export var progressive: bool = false
## The progress goal of the achievement.
@export var progress_goal: int = 0
## Number of increments between each popup display.
## For example, set to 3 to show the popup every 3 increments.
@export var indicate_progress_interval: int = 1
