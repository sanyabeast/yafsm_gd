@tool
class_name StackPlayer extends Node


signal pushed(to: Variant)
signal popped(from: Variant)


enum ResetEventTrigger {
	NONE = -1,
	ALL = 0,
	LAST_TO_DEST = 1
}

var current: Variant:
	get = get_current
var stack: Array:
	set = _set_stack,
	get = _get_stack

var _stack: Array


func _init() -> void:
	_stack = []


func push(to: Variant) -> void:
	var from: Variant = get_current()
	_stack.push_back(to)
	_on_pushed(from, to)
	emit_signal("pushed", to)


func pop() -> void:
	var to: Variant = get_previous()
	var from: Variant = _stack.pop_back()
	_on_popped(from, to)
	emit_signal("popped", from)


func _on_pushed(from: Variant, to: Variant) -> void:
	pass


func _on_popped(from: Variant, to: Variant) -> void:
	pass


func reset(to: int = -1, event: ResetEventTrigger = ResetEventTrigger.ALL) -> void:
	assert(to > -2 and to < _stack.size(), "Reset to index out of bounds")
	var last_index: int = _stack.size() - 1
	var first_state: Variant = ""
	var num_to_pop: int = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current() if i == 0 else first_state
			match event:
				ResetEventTrigger.LAST_TO_DEST:
					_stack.pop_back()
					if i == num_to_pop - 1:
						_stack.push_back(first_state)
						pop()
				ResetEventTrigger.ALL:
					pop()
				_:
					_stack.pop_back()
	elif num_to_pop == 0:
		match event:
			ResetEventTrigger.NONE:
				_stack.pop_back()
			_:
				pop()


func _set_stack(val: Array) -> void:
	push_warning("Attempting to edit read-only state stack directly. Control state machine from setting parameters or call update() instead")


func _get_stack() -> Array:
	return _stack.duplicate()


func get_current() -> Variant:
	if not _stack.is_empty():
		return _stack.back()
	return null


func get_previous() -> Variant:
	if _stack.size() > 1:
		return _stack[_stack.size() - 2]
	return null
