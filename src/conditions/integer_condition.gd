@tool
extends ValueCondition
class_name IntegerCondition


@export var value: int:
	set = set_value,
	get = get_value


func set_value(v: Variant) -> void:
	if value != v:
		value = v
		emit_signal("value_changed", v)
		emit_signal("display_string_changed", display_string())


func get_value() -> int:
	return value


func compare(v: Variant) -> bool:
	if typeof(v) != TYPE_INT:
		return false
	return super.compare(v)
