@tool
extends "res://addons/yafsm/scenes/flowchart/flowchart_layer.gd"


const Utils = preload("res://addons/yafsm/scripts/utils.gd")
const StateNode = preload("res://addons/yafsm/scenes/state_nodes/state_node.tscn")
const StateNodeScript = preload("res://addons/yafsm/scenes/state_nodes/state_node.gd")
const StateDirectory = preload("../src/state_directory.gd")

var editor_accent_color: Color = Color.WHITE:
	set = set_editor_accent_color
var editor_complementary_color: Color = Color.WHITE
var state_machine: Variant
var tween_lines: Tween
var tween_labels: Tween
var tween_nodes: Tween


func debug_update(current_state: String, parameters: Dictionary, local_parameters: Dictionary) -> void:
	_init_tweens()
	if not state_machine:
		return
	var current_dir: StateDirectory = StateDirectory.new(current_state)
	var transitions: Dictionary = state_machine.transitions.get(current_state, {})
	if current_dir.is_nested():
		transitions = state_machine.transitions.get(current_dir.get_end(), {})
	for transition in transitions.values():
		var line: Variant = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		if line:
			var color1: Color = Color.WHITE
			color1.a = 0.1
			var color2: Color = Color.WHITE
			color2.a = 0.5
			if line.self_modulate == color1:
				tween_lines.tween_property(line, "self_modulate", color2, 0.5)
			elif line.self_modulate == color2:
				tween_lines.tween_property(line, "self_modulate", color1, 0.5)
			elif line.self_modulate == Color.WHITE:
				tween_lines.tween_property(line, "self_modulate", color2, 0.5)
			for condition in transition.conditions.values():
				if not ("value" in condition):
					continue
				var value: Variant = parameters.get(str(condition.name))
				value = str(value) if value != null else "?"
				var label: Variant = line.vbox.get_node_or_null(NodePath(str(condition.name)))
				var override_template_var: Variant = line._template_var.get(str(condition.name))
				if override_template_var == null:
					override_template_var = {}
					line._template_var[str(condition.name)] = override_template_var
				override_template_var["value"] = str(value)
				line.update_label()
				var cond_1: bool = condition.compare(parameters.get(str(condition.name)))
				var cond_2: bool = condition.compare(local_parameters.get(str(condition.name)))
				if cond_1 or cond_2:
					tween_labels.tween_property(label, "self_modulate", Color.GREEN.lightened(0.5), 0.01)
				else:
					tween_labels.tween_property(label, "self_modulate", Color.RED.lightened(0.5), 0.01)
	_start_tweens()


func debug_transit_out(from: String, to: String) -> void:
	_init_tweens()
	var from_dir: StateDirectory = StateDirectory.new(from)
	var to_dir: StateDirectory = StateDirectory.new(to)
	var from_node: Variant = content_nodes.get_node_or_null(NodePath(from_dir.get_end()))
	if from_node != null:
		tween_nodes.tween_property(from_node, "self_modulate", editor_complementary_color, 0.01)
		tween_nodes.tween_property(from_node, "self_modulate", Color.WHITE, 1)
	var transitions: Dictionary = state_machine.transitions.get(from, {})
	if from_dir.is_nested():
		transitions = state_machine.transitions.get(from_dir.get_end(), {})
	for transition in transitions.values():
		var line: Variant = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		if line:
			line.template = "{condition_name} {condition_comparation} {condition_value}"
			line.update_label()
			if transition.to == to_dir.get_end():
				tween_lines.tween_property(line, "self_modulate", editor_complementary_color, 0.01)
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
				for condition in transition.conditions.values():
					if not ("value" in condition):
						continue
					var label: Variant = line.vbox.get_node_or_null(NodePath(condition.name))
					tween_labels.tween_property(label, "self_modulate", editor_complementary_color, 0.01)
					tween_labels.tween_property(label, "self_modulate", Color.WHITE, 1)
			else:
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 0.1)
				for condition in transition.conditions.values():
					if not ("value" in condition):
						continue
					var label: Variant = line.vbox.get_node_or_null(NodePath(condition.name))
					if label.self_modulate != Color.WHITE:
						tween_labels.tween_property(label, "self_modulate", Color.WHITE, 0.5)
	if from_dir.is_nested() and from_dir.is_exit():
		transitions = state_machine.transitions.get(from_dir.get_base(), {})
		tween_lines.set_parallel(true)
		for transition in transitions.values():
			var line: Variant = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
			if line:
				tween_lines.tween_property(line, "self_modulate", editor_complementary_color.lightened(0.5), 0.1)
		for transition in transitions.values():
			var line: Variant = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
			if line:
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 0.1)
	_start_tweens()


func debug_transit_in(from: String, to: String) -> void:
	_init_tweens()
	var to_dir: StateDirectory = StateDirectory.new(to)
	var to_node: Variant = content_nodes.get_node_or_null(NodePath(to_dir.get_end()))
	if to_node:
		tween_nodes.tween_property(to_node, "self_modulate", editor_complementary_color, 0.5)
	var transitions: Dictionary = state_machine.transitions.get(to, {})
	if to_dir.is_nested():
		transitions = state_machine.transitions.get(to_dir.get_end(), {})
	for transition in transitions.values():
		var line: Variant = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		line.template = "{condition_name} {condition_comparation} {condition_value}({value})"
	_start_tweens()


func set_editor_accent_color(color: Color) -> void:
	editor_accent_color = color
	editor_complementary_color = Utils.get_complementary_color(color)


func _init_tweens() -> void:
	tween_lines = get_tree().create_tween()
	tween_lines.stop()
	tween_labels = get_tree().create_tween()
	tween_labels.stop()
	tween_nodes = get_tree().create_tween()
	tween_nodes.stop()


func _start_tweens() -> void:
	tween_lines.tween_interval(0.001)
	tween_lines.play()
	tween_labels.tween_interval(0.001)
	tween_labels.play()
	tween_nodes.tween_interval(0.001)
	tween_nodes.play()
