@tool
extends EditorPlugin

const MILESTONE_PANEL = preload("res://addons/milestone/components/milestone_panel.tscn")
var panel


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	panel = MILESTONE_PANEL.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, panel)


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, panel)
	panel.queue_free()