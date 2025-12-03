@tool
extends Resource
class_name Condition


signal name_changed(old: String, new: String)
signal display_string_changed(new: String)


@export var name: String = "":
	set = set_name


func _init(p_name: String = "") -> void:
	name = p_name


func set_name(n: String) -> void:
	if name != n:
		var old: String = name
		name = n
		emit_signal("name_changed", old, n)
		emit_signal("display_string_changed", display_string())


func display_string() -> String:
	return name
