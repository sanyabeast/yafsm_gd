@tool
extends VBoxContainer


const Utils = preload("../../scripts/Utils.gd")
const ConditionEditor = preload("../condition_editors/ConditionEditor.tscn")
const BoolConditionEditor = preload("../condition_editors/BoolConditionEditor.tscn")
const IntegerConditionEditor = preload("../condition_editors/IntegerConditionEditor.tscn")
const FloatConditionEditor = preload("../condition_editors/FloatConditionEditor.tscn")
const StringConditionEditor = preload("../condition_editors/StringConditionEditor.tscn")

@onready var header: Control = $HeaderContainer/Header
@onready var title: Control = $HeaderContainer/Header/Title
@onready var title_icon: TextureRect = $HeaderContainer/Header/Title/Icon
@onready var from: Control = $HeaderContainer/Header/Title/From
@onready var to: Control = $HeaderContainer/Header/Title/To
@onready var condition_count_icon: TextureRect = $HeaderContainer/Header/ConditionCount/Icon
@onready var condition_count_label: Control = $HeaderContainer/Header/ConditionCount/Label
@onready var priority_icon: TextureRect = $HeaderContainer/Header/Priority/Icon
@onready var priority_spinbox: Control = $HeaderContainer/Header/Priority/SpinBox
@onready var target_trigger_checkbox: Control = $HeaderContainer/Header/TargetTrigger/CheckBox
@onready var add: Control = $HeaderContainer/Header/HBoxContainer/Add
@onready var add_popup_menu: PopupMenu = $HeaderContainer/Header/HBoxContainer/Add/PopupMenu
@onready var content_container: Control = $MarginContainer
@onready var condition_list: Control = $MarginContainer/Conditions

var undo_redo: EditorUndoRedoManager
var transition: Variant:
	set = set_transition
var _to_free: Array


func _init() -> void:
	_to_free = []


func _ready() -> void:
	header.gui_input.connect(_on_header_gui_input)
	priority_spinbox.value_changed.connect(_on_priority_spinbox_value_changed)
	target_trigger_checkbox.toggled.connect(_on_target_trigger_checkbox_toggled)
	add.pressed.connect(_on_add_pressed)
	add_popup_menu.index_pressed.connect(_on_add_popup_menu_index_pressed)

	condition_count_icon.texture = get_theme_icon("MirrorX", "EditorIcons")
	priority_icon.texture = get_theme_icon("AnimationTrackGroup", "EditorIcons")


func _exit_tree() -> void:
	free_node_from_undo_redo()


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle_conditions()


func _on_priority_spinbox_value_changed(val: int) -> void:
	set_priority(val)


func _on_target_trigger_checkbox_toggled(toggled_on: bool) -> void:
	set_use_target_as_trigger(toggled_on)


func _on_add_pressed() -> void:
	Utils.popup_on_target(add_popup_menu, add)


func _on_add_popup_menu_index_pressed(index: int) -> void:
	var default_new_condition_name: String = "Param"
	var condition_dup_index: int = 0
	var new_name: String = default_new_condition_name
	for condition_editor in condition_list.get_children():
		var condition_name: String = condition_editor.condition.name
		if condition_name == new_name:
			condition_dup_index += 1
			new_name = "%s%s" % [default_new_condition_name, condition_dup_index]
	var condition: Variant
	match index:
		0:
			condition = Condition.new(new_name)
		1:
			condition = BooleanCondition.new(new_name)
		2:
			condition = IntegerCondition.new(new_name)
		3:
			condition = FloatCondition.new(new_name)
		4:
			condition = StringCondition.new(new_name)
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)
	var editor: Control = create_condition_editor(condition)
	add_condition_editor_action(editor, condition)


func _on_ConditionEditorRemove_pressed(editor: Control) -> void:
	remove_condition_editor_action(editor)


func _on_transition_changed(new_transition: Variant) -> void:
	if not new_transition:
		return

	for condition in transition.conditions.values():
		var editor: Control = create_condition_editor(condition)
		add_condition_editor(editor, condition)
	update_title()
	update_condition_count()
	update_priority_spinbox_value()
	update_target_trigger_checkbox()


func _on_condition_editor_added(editor: Control) -> void:
	editor.undo_redo = undo_redo
	if not editor.remove.pressed.is_connected(_on_ConditionEditorRemove_pressed):
		editor.remove.pressed.connect(_on_ConditionEditorRemove_pressed.bind(editor))
	transition.add_condition(editor.condition)
	update_condition_count()


func add_condition_editor(editor: Control, condition: Variant) -> void:
	condition_list.add_child(editor)
	editor.condition = condition
	_on_condition_editor_added(editor)


func remove_condition_editor(editor: Control) -> void:
	transition.remove_condition(editor.condition.name)
	condition_list.remove_child(editor)
	_to_free.append(editor)
	update_condition_count()


func update_title() -> void:
	from.text = transition.from
	to.text = transition.to


func update_condition_count() -> void:
	var count: int = transition.conditions.size()
	condition_count_label.text = str(count)
	if count == 0:
		hide_conditions()
	else:
		show_conditions()


func update_priority_spinbox_value() -> void:
	priority_spinbox.value = transition.priority
	priority_spinbox.apply()


func update_target_trigger_checkbox() -> void:
	target_trigger_checkbox.set_pressed_no_signal(transition.use_target_as_trigger)


func set_priority(value: int) -> void:
	transition.priority = value


func set_use_target_as_trigger(value: bool) -> void:
	transition.use_target_as_trigger = value


func show_conditions() -> void:
	content_container.visible = true


func hide_conditions() -> void:
	content_container.visible = false


func toggle_conditions() -> void:
	content_container.visible = !content_container.visible


func create_condition_editor(condition: Variant) -> Control:
	var editor: Control
	if condition is BooleanCondition:
		editor = BoolConditionEditor.instantiate()
	elif condition is IntegerCondition:
		editor = IntegerConditionEditor.instantiate()
	elif condition is FloatCondition:
		editor = FloatConditionEditor.instantiate()
	elif condition is StringCondition:
		editor = StringConditionEditor.instantiate()
	else:
		editor = ConditionEditor.instantiate()
	return editor


func add_condition_editor_action(editor: Control, condition: Variant) -> void:
	undo_redo.create_action("Add Transition Condition")
	undo_redo.add_do_method(self, "add_condition_editor", editor, condition)
	undo_redo.add_undo_method(self, "remove_condition_editor", editor)
	undo_redo.commit_action()


func remove_condition_editor_action(editor: Control) -> void:
	undo_redo.create_action("Remove Transition Condition")
	undo_redo.add_do_method(self, "remove_condition_editor", editor)
	undo_redo.add_undo_method(self, "add_condition_editor", editor, editor.condition)
	undo_redo.commit_action()


func set_transition(t: Variant) -> void:
	if transition != t:
		transition = t
		_on_transition_changed(t)


func free_node_from_undo_redo() -> void:
	for node in _to_free:
		if is_instance_valid(node):
			var history_id: int = undo_redo.get_object_history_id(node)
			undo_redo.get_history_undo_redo(history_id).clear_history(false)
			node.queue_free()

	_to_free.clear()
