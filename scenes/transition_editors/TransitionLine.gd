@tool
extends "res://addons/yafsm/scenes/flowchart/FlowChartLine.gd"


const Transition = preload("../../src/transitions/Transition.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")
const hi_res_font: Font = preload("res://addons/yafsm/assets/fonts/sans_serif.tres")

@export var upright_angle_range: float = 5.0

@onready var label_margin: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer

var undo_redo: EditorUndoRedoManager
var transition: Transition:
	set = set_transition
var template: String = "{condition_name} {condition_comparation} {condition_value}"
var _template_var: Dictionary = {}


func _init() -> void:
	super._init()
	
	set_transition(Transition.new())


func _draw() -> void:
	super._draw()

	var abs_rotation: float = abs(rotation)
	var is_flip: bool = abs_rotation > deg_to_rad(90.0)
	var is_upright: bool = (abs_rotation > (deg_to_rad(90.0) - deg_to_rad(upright_angle_range))) and (abs_rotation < (deg_to_rad(90.0) + deg_to_rad(upright_angle_range)))

	if is_upright:
		var x_offset: float = label_margin.size.x / 2
		var y_offset: float = -label_margin.size.y
		label_margin.position = Vector2((size.x - x_offset) / 2, 0)
	else:
		var x_offset: float = label_margin.size.x
		var y_offset: float = -label_margin.size.y
		if is_flip:
			label_margin.rotation = deg_to_rad(180)
			label_margin.position = Vector2((size.x + x_offset) / 2, 0)
		else:
			label_margin.rotation = deg_to_rad(0)
			label_margin.position = Vector2((size.x - x_offset) / 2, y_offset)


func update_label() -> void:
	if transition:
		var template_var: Dictionary = {"condition_name": "", "condition_comparation": "", "condition_value": null}
		var auto_trigger_label_name: String = "__auto_trigger__"
		
		for label in vbox.get_children():
			var label_name_str: String = str(label.name)
			if label_name_str != auto_trigger_label_name and not (label_name_str in transition.conditions.keys()):
				vbox.remove_child(label)
				label.queue_free()
		
		if transition.use_target_as_trigger:
			var auto_label: Variant = vbox.get_node_or_null(NodePath(auto_trigger_label_name))
			if not auto_label:
				auto_label = Label.new()
				auto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				auto_label.add_theme_font_override("font", hi_res_font)
				auto_label.name = auto_trigger_label_name
				vbox.add_child(auto_label)
				vbox.move_child(auto_label, 0)
			auto_label.text = "→ %s" % transition.to
			auto_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		else:
			var auto_label: Variant = vbox.get_node_or_null(NodePath(auto_trigger_label_name))
			if auto_label:
				vbox.remove_child(auto_label)
				auto_label.queue_free()
		
		for condition in transition.conditions.values():
			var label: Variant = vbox.get_node_or_null(NodePath(condition.name))
			if not label:
				label = Label.new()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_override("font", hi_res_font)
				label.name = condition.name
				vbox.add_child(label)
			if "value" in condition:
				template_var["condition_name"] = condition.name
				template_var["condition_comparation"] = ValueCondition.COMPARATION_SYMBOLS[condition.comparation]
				template_var["condition_value"] = condition.get_value_string()
				label.text = template.format(template_var)
				var override_template_var: Variant = _template_var.get(condition.name)
				if override_template_var:
					label.text = label.text.format(override_template_var)
			else:
				label.text = condition.name
	queue_redraw()


func _on_transition_changed(new_transition: Transition) -> void:
	if not is_inside_tree():
		return

	if new_transition:
		new_transition.condition_added.connect(_on_transition_condition_added)
		new_transition.condition_removed.connect(_on_transition_condition_removed)
		new_transition.use_target_as_trigger_changed.connect(_on_use_target_as_trigger_changed)
		for condition in new_transition.conditions.values():
			condition.name_changed.connect(_on_condition_name_changed)
			condition.display_string_changed.connect(_on_condition_display_string_changed)
	update_label()


func _on_transition_condition_added(condition: Variant) -> void:
	condition.name_changed.connect(_on_condition_name_changed)
	condition.display_string_changed.connect(_on_condition_display_string_changed)
	update_label()


func _on_transition_condition_removed(condition: Variant) -> void:
	condition.name_changed.disconnect(_on_condition_name_changed)
	condition.display_string_changed.disconnect(_on_condition_display_string_changed)
	update_label()


func _on_condition_name_changed(from: String, to: String) -> void:
	var label: Variant = vbox.get_node_or_null(NodePath(from))
	if label:
		label.name = to
	update_label()


func _on_condition_display_string_changed(display_string: String) -> void:
	update_label()



func _on_use_target_as_trigger_changed(enabled: bool) -> void:
	update_label()


func set_transition(t: Transition) -> void:
	if transition != t:
		if transition:
			if transition.condition_added.is_connected(_on_transition_condition_added):
				transition.condition_added.disconnect(_on_transition_condition_added)
			if transition.use_target_as_trigger_changed.is_connected(_on_use_target_as_trigger_changed):
				transition.use_target_as_trigger_changed.disconnect(_on_use_target_as_trigger_changed)
		transition = t
		_on_transition_changed(transition)
