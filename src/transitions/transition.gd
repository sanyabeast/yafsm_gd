@tool
extends Resource
class_name Transition


signal condition_added(condition: Variant)
signal condition_removed(condition: Variant)
signal use_target_as_trigger_changed(enabled: bool)


@export var from: String
@export var to: String
@export var conditions: Dictionary:
	set = set_conditions,
	get = get_conditions
@export var priority: int = 0
@export var use_target_as_trigger: bool = false:
	set = set_use_target_as_trigger

var _conditions: Dictionary


func _init(p_from: String = "", p_to: String = "", p_conditions: Dictionary = {}) -> void:
	from = p_from
	to = p_to
	_conditions = p_conditions


func transit(params: Dictionary = {}, local_params: Dictionary = {}) -> String:
	if use_target_as_trigger:
		var has_target_trigger: bool = params.get(to) == null and params.has(to)
		var has_local_target_trigger: bool = local_params.get(to) == null and local_params.has(to)
		if not (has_target_trigger or has_local_target_trigger):
			return ""
	
	var can_transit: bool = _conditions.size() > 0
	for condition in _conditions.values():
		var has_param: bool = params.has(condition.name)
		var has_local_param: bool = local_params.has(condition.name)
		if has_param or has_local_param:
			var value: Variant = local_params.get(condition.name) if has_local_param else params.get(condition.name)
			if value == null:
				can_transit = can_transit and true
			else:
				if "value" in condition:
					can_transit = can_transit and condition.compare(value)
		else:
			can_transit = false
	if can_transit or _conditions.size() == 0:
		return to
	return ""


func add_condition(condition: Variant) -> bool:
	if condition.name in _conditions:
		return false

	_conditions[condition.name] = condition
	emit_signal("condition_added", condition)
	return true


func remove_condition(name: String) -> bool:
	var condition: Variant = _conditions.get(name)
	if condition:
		_conditions.erase(name)
		emit_signal("condition_removed", condition)
		return true
	return false


func change_condition_name(from: String, to: String) -> bool:
	if not (from in _conditions) or to in _conditions:
		return false

	var condition = _conditions[from]
	condition.name = to
	_conditions.erase(from)
	_conditions[to] = condition
	return true


func get_unique_name(name: String) -> String:
	var new_name: String = name
	var i: int = 1
	while new_name in _conditions:
		new_name = name + str(i)
		i += 1
	return new_name


func equals(obj: Variant) -> bool:
	if obj == null:
		return false
	if not ("from" in obj and "to" in obj):
		return false

	return from == obj.from and to == obj.to


func get_conditions() -> Dictionary:
	return _conditions.duplicate()


func set_conditions(val: Dictionary) -> void:
	_conditions = val


func set_use_target_as_trigger(value: bool) -> void:
	if use_target_as_trigger != value:
		use_target_as_trigger = value
		emit_signal("use_target_as_trigger_changed", value)


static func sort(a: Transition, b: Transition) -> bool:
	if a.priority > b.priority:
		return true
	return false
