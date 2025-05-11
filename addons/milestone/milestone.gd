@tool
extends EditorPlugin

const MILESTONE_PANEL = preload("uid://b35o10vjk7vse")
var milestone_view

## Used for generating the preview icon (in the Editor) of the achievement resource.
const PREVIEW_GENERATOR = preload("uid://bbshmcisuacik")
var preview_gen

var achievements_resource: Script = preload("uid://dtyojmellf4e5")

func _enable_plugin() -> void:
	add_autoload_singleton("AchievementManager", "autoload/achievement_manager.gd")

	add_settings()

func _disable_plugin() -> void:
	remove_autoload_singleton("AchievementManager")

func _enter_tree() -> void:
	Engine.set_meta("MilestonePlugin", self)

	milestone_view = MILESTONE_PANEL.instantiate()

	add_custom_type("Achievement", "Resource", achievements_resource, load("uid://d186rx7mxnthd"))

	_make_visible(false)
	EditorInterface.get_editor_main_screen().add_child(milestone_view)

	preview_gen = PREVIEW_GENERATOR.new()
	EditorInterface.get_resource_previewer().add_preview_generator(preview_gen)
	add_settings()

func _exit_tree() -> void:
	remove_custom_type("Achievement")

	if milestone_view:
		milestone_view.queue_free()

	if preview_gen:
		EditorInterface.get_resource_previewer().remove_preview_generator(preview_gen)

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if is_instance_valid(milestone_view):
		milestone_view.visible = visible

## Get the current path of the plugin
func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()

func _get_plugin_name() -> String:
	return "Milestone"

func _get_plugin_icon() -> Texture2D:
	return load("uid://ctdctl2mfp36l")

func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(get_plugin_path() + "/plugin.cfg")
	return config.get_value("plugin", "version")

func add_settings() -> void:
	if not ProjectSettings.has_setting("milestone/general/achievements_path"):
		ProjectSettings.set_setting("milestone/general/achievements_path", get_plugin_path() + "/demo/achievements/")
	if not ProjectSettings.has_setting("milestone/debug/print_errors"):
		ProjectSettings.set_setting("milestone/debug/print_errors", true)
	if not ProjectSettings.has_setting("milestone/debug/print_output"):
		ProjectSettings.set_setting("milestone/debug/print_output", true)
	if not ProjectSettings.has_setting("milestone/general/save_as_json"):
		ProjectSettings.set_setting("milestone/general/save_as_json", true)

	ProjectSettings.save()
