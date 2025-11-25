@tool
@icon("../../assets/icons/state_machine_icon.png")
extends State
class_name StateMachine


signal transition_added(transition: Variant)
signal transition_removed(from_state: String, to_state: String)


@export var states: Dictionary:
	get = get_states,
	set = set_states
@export var transitions: Dictionary:
	get = get_transitions,
	set = set_transitions

var _states: Dictionary
var _transitions: Dictionary


func _init(p_name: String = "", p_transitions: Dictionary = {}, p_states: Dictionary = {}) -> void:
	super._init(p_name)
	_transitions = p_transitions
	_states = p_states



func transit(current_state: String, params: Dictionary = {}, local_params: Dictionary = {}) -> String:
	var nested_states: PackedStringArray = current_state.split("/")
	var is_nested: bool = nested_states.size() > 1
	var end_state_machine: StateMachine = self
	var base_path: String = ""
	for i in nested_states.size() - 1:
		var state: String = nested_states[i]
		base_path = join_path(base_path, [state])
		if end_state_machine != self:
			end_state_machine = end_state_machine.states[state]
		else:
			end_state_machine = _states[state]

	if is_nested:
		var is_nested_exit: bool = nested_states[nested_states.size()-1] == State.EXIT_STATE
		if is_nested_exit:
			var end_state_machine_parent_path: String = ""
			for i in nested_states.size() - 2:
				end_state_machine_parent_path = join_path(end_state_machine_parent_path, [nested_states[i]])
			var end_state_machine_parent: StateMachine = get_state(end_state_machine_parent_path)
			var normalized_current_state: String = end_state_machine.name
			var next_state: String = end_state_machine_parent.transit(normalized_current_state, params)
			if next_state:
				next_state = join_path(end_state_machine_parent_path, [next_state])
			return next_state
	
	var from_transitions: Variant = end_state_machine.transitions.get(nested_states[nested_states.size()-1])
	if from_transitions:
		var from_transitions_array: Array = from_transitions.values()
		from_transitions_array.sort_custom(func(a, b): Transition.sort(a, b))
		
		for transition in from_transitions_array:
			var next_state: String = transition.transit(params, local_params)
			if next_state:
				if "states" in end_state_machine.states[next_state]:
					next_state = join_path(base_path, [next_state, State.ENTRY_STATE])
				else:
					next_state = join_path(base_path, [next_state])
				return next_state
	return ""



func get_state(path: String) -> Variant:
	var state: Variant
	if path.is_empty():
		state = self
	else:
		var nested_states: PackedStringArray = path.split("/")
		for i in nested_states.size():
			var dir: String = nested_states[i]
			if state:
				state = state.states[dir]
			else:
				state = _states[dir]
	return state


func add_state(state: State) -> State:
	if not state:
		return null
	if state.name in _states:
		return null

	_states[state.name] = state
	return state


func remove_state(state: String) -> bool:
	return _states.erase(state)


func change_state_name(from: String, to: String) -> bool:
	if not (from in _states) or to in _states:
		return false

	for state_key in _states.keys():
		var state: State = _states[state_key]
		var is_name_changing_state: bool = state_key == from
		if is_name_changing_state:
			state.name = to
			_states[to] = state
			_states.erase(from)
		for from_key in _transitions.keys():
			var from_transitions: Dictionary = _transitions[from_key]
			if from_key == from:
				_transitions.erase(from)
				_transitions[to] = from_transitions
			for to_key in from_transitions.keys():
				var transition: Variant = from_transitions[to_key]
				if transition.from == from:
					transition.from = to
				elif transition.to == from:
					transition.to = to
					if not is_name_changing_state:
						from_transitions.erase(from)
						from_transitions[to] = transition
	return true


func add_transition(transition: Variant) -> void:
	if transition.from == "" or transition.to == "":
		push_warning("Transition missing from/to (%s/%s)" % [transition.from, transition.to])
		return

	var from_transitions: Dictionary
	if transition.from in _transitions:
		from_transitions = _transitions[transition.from]
	else:
		from_transitions = {}
		_transitions[transition.from] = from_transitions

	from_transitions[transition.to] = transition
	emit_signal("transition_added", transition)


func remove_transition(from_state: String, to_state: String) -> void:
	var from_transitions: Variant = _transitions.get(from_state)
	if from_transitions:
		if to_state in from_transitions:
			from_transitions.erase(to_state)
			if from_transitions.is_empty():
				_transitions.erase(from_state)
			emit_signal("transition_removed", from_state, to_state)


func get_entries() -> Array:
	return _transitions[State.ENTRY_STATE].values()


func get_exits() -> Array:
	return _transitions[State.EXIT_STATE].values()


func has_entry() -> bool:
	return State.ENTRY_STATE in _states


func has_exit() -> bool:
	return State.EXIT_STATE in _states


func get_states() -> Dictionary:
	return _states.duplicate()


func set_states(val: Dictionary) -> void:
	_states = val


func get_transitions() -> Dictionary:
	return _transitions.duplicate()


func set_transitions(val: Dictionary) -> void:
	_transitions = val


static func join_path(base: String, dirs: Array) -> String:
	var path: String = base
	for dir in dirs:
		if path.is_empty():
			path = dir
		else:
			path = str(path, "/", dir)
	return path


static func validate(state_machine: StateMachine) -> bool:
	var validated: bool = false
	for from_key in state_machine.transitions.keys():
		if not (from_key in state_machine.states):
			validated = true
			push_warning("gd-YAFSM ValidationError: Non-existing state(%s) found in transition" % from_key)
			state_machine.transitions.erase(from_key)
			continue

		var from_transition: Dictionary = state_machine.transitions[from_key]
		for to_key in from_transition.keys():
			if not (to_key in state_machine.states):
				validated = true
				push_warning("gd-YAFSM ValidationError: Non-existing state(%s) found in transition(%s -> %s)" % [to_key, from_key, to_key])
				from_transition.erase(to_key)
				continue

			var to_transition: Variant = from_transition[to_key]
			if to_key != to_transition.to:
				validated = true
				push_warning("gd-YAFSM ValidationError: Mismatch of StateMachine.transitions key(%s) with Transition.to(%s)" % [to_key, to_transition.to])
				to_transition.to = to_key

			if to_transition.from == to_transition.to:
				validated = true
				push_warning("gd-YAFSM ValidationError: Self connecting transition(%s -> %s)" % [to_transition.from, to_transition.to])
				from_transition.erase(to_key)
	return validated
