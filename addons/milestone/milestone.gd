@tool
extends EditorPlugin

const MILESTONE_PANEL = preload("res://addons/milestone/components/milestone_panel.tscn")

var milestone_view


func _enable_plugin() -> void:
	add_autoload_singleton("MILESTONE", "res://addons/milestone/autoload/milestone.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("MILESTONE")

func _enter_tree() -> void:
	milestone_view = MILESTONE_PANEL.instantiate()
	milestone_view.hide()
	get_editor_interface().get_editor_main_screen().add_child(milestone_view)


func _exit_tree() -> void:
	if milestone_view:
		milestone_view.queue_free()