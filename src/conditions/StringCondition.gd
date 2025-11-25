@tool
extends ValueCondition
class_name StringCondition


@export var value: String:
	set = set_value,
	get = get_value


func set_value(v: Variant) -> void:
	if value != v:
		value = v
		emit_signal("value_changed", v)
		emit_signal("display_string_changed", display_string())


func get_value() -> String:
	return value


func get_value_string() -> String:
	return "\"%s\"" % value


func compare(v: Variant) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	return super.compare(v)
