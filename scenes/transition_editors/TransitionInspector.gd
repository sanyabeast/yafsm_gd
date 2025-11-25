@tool
extends EditorInspectorPlugin
const Transition = preload("res://addons/yafsm/src/transitions/Transition.gd")

const TransitionEditor = preload("res://addons/yafsm/scenes/transition_editors/TransitionEditor.tscn")

var undo_redo

var transition_icon

func _can_handle(object):
	return object is Transition

func _parse_property(object, type, path, hint, hint_text, usage, wide) -> bool:
	match path:
		"from":
			return true
		"to":
			return true
		"conditions":
			var transition_editor = TransitionEditor.instantiate()
			transition_editor.undo_redo = undo_redo
			add_custom_control(transition_editor)
			transition_editor.ready.connect(_on_transition_editor_tree_entered.bind(transition_editor, object))
			return true
		"priority":
			return true
		"use_target_as_trigger":
			return true
	return false

func _on_transition_editor_tree_entered(editor, transition):
	editor.transition = transition
	if transition_icon:
		editor.title_icon.texture = transition_icon
