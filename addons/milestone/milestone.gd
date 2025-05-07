@tool
extends EditorPlugin

const MILESTONE_PANEL = preload("./components/milestone_panel.tscn")
var milestone_view

## Used for generating the preview icon (in the Editor) of the achievement resource.
const PREVIEW_GENERATOR = preload("./scripts/resource_icon_gen/preview_generator.gd")
var preview_gen


func _enable_plugin() -> void:
	add_autoload_singleton("AchievementManager", get_plugin_path() + "/autoload/achievement_manager.gd")

	add_settings()

func _disable_plugin() -> void:
	remove_autoload_singleton("AchievementManager")

func _enter_tree() -> void:
	milestone_view = MILESTONE_PANEL.instantiate()

	_make_visible(false)
	get_editor_interface().get_editor_main_screen().add_child(milestone_view)

	preview_gen = PREVIEW_GENERATOR.new()
	get_editor_interface().get_resource_previewer().add_preview_generator(preview_gen)

func _exit_tree() -> void:
	if milestone_view:
		milestone_view.queue_free()

	if preview_gen:
		get_editor_interface().get_resource_previewer().remove_preview_generator(preview_gen)

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
	return load(get_plugin_path() + "/assets/icon.svg")

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