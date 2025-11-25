@tool
extends Condition
class_name ValueCondition


signal comparation_changed(new_comparation: Comparation)
signal value_changed(new_value: Variant)


enum Comparation {
	EQUAL,
	INEQUAL,
	GREATER,
	LESSER,
	GREATER_OR_EQUAL,
	LESSER_OR_EQUAL
}

const COMPARATION_SYMBOLS: Array = [
	"==",
	"!=",
	">",
	"<",
	"≥",
	"≤"
]

@export var comparation: Comparation = Comparation.EQUAL:
	set = set_comparation


func _init(p_name: String = "", p_comparation: Comparation = Comparation.EQUAL) -> void:
	super._init(p_name)
	comparation = p_comparation


func set_comparation(c: Comparation) -> void:
	if comparation != c:
		comparation = c
		emit_signal("comparation_changed", c)
		emit_signal("display_string_changed", display_string())


func set_value(v: Variant) -> void:
	pass


func get_value() -> Variant:
	return null


func get_value_string() -> String:
	return get_value()


func compare(v: Variant) -> bool:
	if v == null:
		return false

	match comparation:
		Comparation.EQUAL:
			return v == get_value()
		Comparation.INEQUAL:
			return v != get_value()
		Comparation.GREATER:
			return v > get_value()
		Comparation.LESSER:
			return v < get_value()
		Comparation.GREATER_OR_EQUAL:
			return v >= get_value()
		Comparation.LESSER_OR_EQUAL:
			return v <= get_value()
	return false


func display_string() -> String:
	return "%s %s %s" % [super.display_string(), COMPARATION_SYMBOLS[comparation], get_value_string()]
