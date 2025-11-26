@tool
class_name StateMachinePlayer extends StackPlayer


signal transited(from: String, to: String)
signal entered(to: String)
signal exited(from: String)
signal updated(state: String, delta: float)

enum UpdateProcessMode {
	PHYSICS,
	IDLE,
	MANUAL
}

@export var state_machine: StateMachine
@export var active: bool = true:
	set = set_active
@export var autostart: bool = true
@export var update_process_mode: UpdateProcessMode = UpdateProcessMode.IDLE:
	set = set_update_process_mode

var _is_started: bool = false
var _parameters: Dictionary
var _local_parameters: Dictionary
var _is_update_locked: bool = true
var _was_transited: bool = false
var _is_param_edited: bool = false


func _init() -> void:
	super._init()
	
	if Engine.is_editor_hint():
		return

	_parameters = {}
	_local_parameters = {}
	_was_transited = true

func _get_configuration_warnings() -> PackedStringArray:
	var _errors: Array[String] = []

	if state_machine:
		if not state_machine.has_entry():
			_errors.append("The StateMachine provided does not have an Entry node.\nPlease create one to it works properly.")
	else:
		_errors.append("StateMachinePlayer needs a StateMachine to run.\nPlease create a StateMachine resource to it.")
	
	return PackedStringArray(_errors)

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	set_process(false)
	set_physics_process(false)
	call_deferred("_initiate")


func _initiate() -> void:
	if autostart:
		start()
	_on_active_changed()
	_on_update_process_mode_changed()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_start()
	update(delta)
	_update_end()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_start()
	update(delta)
	_update_end()

func _transit() -> void:
	if not active:
		return
	if not _is_param_edited and not _was_transited:
		return

	var from: String = get_current()
	var local_params: Dictionary = _local_parameters.get(path_backward(from), {})
	var next_state: String = state_machine.transit(get_current(), _parameters, local_params)
	if next_state:
		if stack.has(next_state):
			reset(stack.find(next_state))
		else:
			push(next_state)
	var to: String = next_state
	_was_transited = next_state != null and next_state != ""
	_is_param_edited = false
	_flush_trigger(_parameters)
	_flush_trigger(_local_parameters, true)

	if _was_transited:
		_on_state_changed(from, to)


func _on_state_changed(from: String, to: String) -> void:
	match to:
		State.ENTRY_STATE:
			emit_signal("entered", "")
		State.EXIT_STATE:
			set_active(false)
			emit_signal("exited", "")
	
	if to.ends_with(State.ENTRY_STATE) and to.length() > State.ENTRY_STATE.length():
		var state: String = path_backward(get_current())
		emit_signal("entered", state)
	elif to.ends_with(State.EXIT_STATE) and to.length() > State.EXIT_STATE.length():
		var state: String = path_backward(get_current())
		clear_param(state, false)
		emit_signal("exited", state)

	emit_signal("transited", from, to)

func _update_start() -> void:
	_is_update_locked = false


func _update_end() -> void:
	_is_update_locked = true


func _on_updated(state: String, delta: float) -> void:
	pass


func _on_update_process_mode_changed() -> void:
	if not active:
		return

	match update_process_mode:
		UpdateProcessMode.PHYSICS:
			set_physics_process(true)
			set_process(false)
		UpdateProcessMode.IDLE:
			set_physics_process(false)
			set_process(true)
		UpdateProcessMode.MANUAL:
			set_physics_process(false)
			set_process(false)


func _on_active_changed() -> void:
	if Engine.is_editor_hint():
		return

	if active:
		_on_update_process_mode_changed()
		_transit()
	else:
		set_physics_process(false)
		set_process(false)


func _flush_trigger(params: Dictionary, nested: bool = false) -> void:
	for param_key in params.keys():
		var value: Variant = params[param_key]
		if nested and value is Dictionary:
			_flush_trigger(value)
		if value == null:
			params.erase(param_key)


func reset(to: int = -1, event: ResetEventTrigger = ResetEventTrigger.LAST_TO_DEST) -> void:
	super.reset(to, event)
	_was_transited = true


func start() -> void:
	assert(state_machine != null, "A StateMachine resource is required to start this StateMachinePlayer.")
	assert(state_machine.has_entry(), "The StateMachine provided does not have an Entry node.")
	push(State.ENTRY_STATE)
	emit_signal("entered", "")
	_was_transited = true
	_is_started = true


func restart(is_active: bool = true, preserve_params: bool = false) -> void:
	reset()
	set_active(is_active)
	if not preserve_params:
		clear_param("", false)
	start()


func update(delta: float = get_physics_process_delta_time()) -> void:
	if not active:
		return
	if update_process_mode != UpdateProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode %s" % UpdateProcessMode.keys()[update_process_mode])

	_transit()
	var current_state: String = get_current()
	_on_updated(current_state, delta)
	emit_signal("updated", current_state, delta)
	if update_process_mode == UpdateProcessMode.MANUAL:
		if _was_transited:
			call_deferred("update")

func set_trigger(name: String, auto_update: bool = true) -> void:
	set_param(name, null, auto_update)


func set_nested_trigger(path: String, name: String, auto_update: bool = true) -> void:
	set_nested_param(path, name, null, auto_update)


func set_param(name: String, value: Variant, auto_update: bool = true) -> void:
	var path: String = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	set_nested_param(path, name, value, auto_update)


func set_nested_param(path: String, name: String, value: Variant, auto_update: bool = true) -> void:
	if path.is_empty():
		_parameters[name] = value
	else:
		var local_params: Variant = _local_parameters.get(path)
		if local_params is Dictionary:
			local_params[name] = value
		else:
			local_params = {}
			local_params[name] = value
			_local_parameters[path] = local_params
	_on_param_edited(auto_update)

func erase_param(name: String, auto_update: bool = true) -> bool:
	var path: String = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return erase_nested_param(path, name, auto_update)


func erase_nested_param(path: String, name: String, auto_update: bool = true) -> bool:
	var result: bool = false
	if path.is_empty():
		result = _parameters.erase(name)
	else:
		result = _local_parameters.get(path, {}).erase(name)
	_on_param_edited(auto_update)
	return result


func clear_param(path: String = "", auto_update: bool = true) -> void:
	if path.is_empty():
		_parameters.clear()
	else:
		_local_parameters.get(path, {}).clear()
		for param_key in _local_parameters.keys():
			if param_key.begins_with(path):
				_local_parameters.erase(param_key)


func _on_param_edited(auto_update: bool = true) -> void:
	_is_param_edited = true
	if update_process_mode == UpdateProcessMode.MANUAL and auto_update and _is_started:
		update()

func get_param(name: String, default: Variant = null) -> Variant:
	var path: String = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return get_nested_param(path, name, default)


func get_nested_param(path: String, name: String, default: Variant = null) -> Variant:
	if path.is_empty():
		return _parameters.get(name, default)
	else:
		var local_params: Dictionary = _local_parameters.get(path, {})
		return local_params.get(name, default)


func get_params() -> Dictionary:
	return _parameters.duplicate()


func has_param(name: String) -> bool:
	var path: String = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return has_nested_param(path, name)


func has_nested_param(path: String, name: String) -> bool:
	if path.is_empty():
		return name in _parameters
	else:
		var local_params: Dictionary = _local_parameters.get(path, {})
		return name in local_params


func is_entered() -> bool:
	return State.ENTRY_STATE in stack


func is_exited() -> bool:
	return get_current() == State.EXIT_STATE


func set_active(v: bool) -> void:
	if active != v:
		if v:
			if is_exited():
				push_warning("Attempting to make exited StateMachinePlayer active, call reset() then set_active() instead")
				return
		active = v
		_on_active_changed()


func set_update_process_mode(mode: UpdateProcessMode) -> void:
	if update_process_mode != mode:
		update_process_mode = mode
		_on_update_process_mode_changed()


func get_current() -> String:
	var v: Variant = super.get_current()
	return v if v else ""


func get_previous() -> String:
	var v: Variant = super.get_previous()
	return v if v else ""


func get_state_names() -> PackedStringArray:
	if state_machine:
		return PackedStringArray(state_machine.states.keys())
	return PackedStringArray()


static func node_path_to_state_path(node_path: String) -> String:
	var p: String = node_path.replace("root", "")
	if p.begins_with("/"):
		p = p.substr(1)
	return p


static func state_path_to_node_path(state_path: String) -> String:
	var path: String = state_path
	if path.is_empty():
		path = "root"
	else:
		path = str("root/", path)
	return path


static func path_backward(path: String) -> String:
	return path.substr(0, path.rfind("/"))


static func path_end_dir(path: String) -> String:
	return path.right(path.length()-1 - path.rfind("/"))
