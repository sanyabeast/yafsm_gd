@tool
extends EditorInspectorPlugin


const Transition = preload("res://addons/yafsm/src/transitions/Transition.gd")
const TransitionEditor = preload("res://addons/yafsm/scenes/transition_editors/TransitionEditor.tscn")

var undo_redo: EditorUndoRedoManager
var transition_icon: Texture2D


func _can_handle(object: Object) -> bool:
	return object is Transition


func _parse_property(object: Object, type: Variant, path: String, hint: PropertyHint, hint_text: String, usage: int, wide: bool) -> bool:
	match path:
		"from":
			return true
		"to":
			return true
		"conditions":
			var transition_editor: Control = TransitionEditor.instantiate()
			transition_editor.undo_redo = undo_redo
			add_custom_control(transition_editor)
			transition_editor.ready.connect(_on_transition_editor_tree_entered.bind(transition_editor, object))
			return true
		"priority":
			return true
		"use_target_as_trigger":
			return true
	return false


func _on_transition_editor_tree_entered(editor: Control, transition: Transition) -> void:
	editor.transition = transition
	if transition_icon:
		editor.title_icon.texture = transition_icon
