extends EditorInspectorPlugin


const State = preload("res://addons/yafsm/src/states/State.gd")


func _can_handle(object: Object) -> bool:
	return object is State


func _parse_property(object: Object, type: Variant, path: String, hint: PropertyHint, hint_text: String, usage: int, wide: bool) -> bool:
	return false
