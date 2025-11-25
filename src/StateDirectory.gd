@tool
extends RefCounted


const State = preload("states/State.gd")

var path: String
var current: String:
	get = get_current
var base: String:
	get = get_base
var end: String:
	get = get_end

var _current_index: int = 0
var _dirs: Array = [""]


func _init(p: String) -> void:
	path = p
	_dirs += Array(p.split("/"))


func next() -> Variant:
	if has_next():
		_current_index += 1
		return get_current_end()

	return null


func back() -> Variant:
	if has_back():
		_current_index -= 1
		return get_current_end()
	
	return null


func goto(index: int) -> String:
	assert(index > -1 and index < _dirs.size())
	_current_index = index
	return get_current_end()


func has_next() -> bool:
	return _current_index < _dirs.size() - 1


func has_back() -> bool:
	return _current_index > 0


func get_current() -> String:
	var packed_string_array: PackedStringArray = PackedStringArray(_dirs.slice(get_base_index(), _current_index+1))
	return "/".join(packed_string_array)


func get_current_end() -> String:
	var current_path: String = get_current()
	return current_path.right(current_path.length()-1 - current_path.rfind("/"))


func get_base_index() -> int:
	return 1


func get_end_index() -> int:
	return _dirs.size() - 1


func get_base() -> String:
	return _dirs[get_base_index()]


func get_end() -> String:
	return _dirs[get_end_index()]


func get_dirs() -> Array:
	return _dirs.duplicate()


func is_entry() -> bool:
	return get_end() == State.ENTRY_STATE


func is_exit() -> bool:
	return get_end() == State.EXIT_STATE


func is_nested() -> bool:
	return _dirs.size() > 2
