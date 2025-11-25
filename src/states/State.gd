@tool
extends Resource
class_name State


signal name_changed(new_name: String)


const ENTRY_STATE: String = "Entry"
const EXIT_STATE: String = "Exit"
const META_GRAPH_OFFSET: String = "graph_offset"

@export var name: String = "":
	set = set_name

var graph_offset: Vector2:
	set = set_graph_offset,
	get = get_graph_offset


func _init(p_name: String = "") -> void:
	name = p_name


func is_entry() -> bool:
	return name == ENTRY_STATE


func is_exit() -> bool:
	return name == EXIT_STATE


func set_graph_offset(offset: Vector2) -> void:
	set_meta(META_GRAPH_OFFSET, offset)


func get_graph_offset() -> Vector2:
	if has_meta(META_GRAPH_OFFSET):
		return get_meta(META_GRAPH_OFFSET)
	return Vector2.ZERO


func set_name(n: String) -> void:
	if name != n:
		name = n
		emit_signal("name_changed", name)
