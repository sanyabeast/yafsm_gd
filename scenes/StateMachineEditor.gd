@tool
extends "res://addons/yafsm/scenes/flowchart/FlowChart.gd"


const StateMachine = preload("../src/states/StateMachine.gd")
const Transition = preload("../src/transitions/Transition.gd")
const State = preload("../src/states/State.gd")
const StateDirectory = preload("../src/StateDirectory.gd")
const StateNode = preload("state_nodes/StateNode.tscn")
const TransitionLine = preload("transition_editors/TransitionLine.tscn")
const StateNodeScript = preload("state_nodes/StateNode.gd")
const StateMachineEditorLayer = preload("StateMachineEditorLayer.gd")
const PathViewer = preload("PathViewer.gd")

signal inspector_changed(property: String)
signal debug_mode_changed(new_debug_mode: bool)

const ENTRY_STATE_MISSING_MSG = {
	"key": "entry_state_missing",
	"text": "Entry State missing, it will never get started. Right-click -> \"Add Entry\"."
}
const EXIT_STATE_MISSING_MSG = {
	"key": "exit_state_missing",
	"text": "Exit State missing, it will never exit from nested state. Right-click -> \"Add Exit\"."
}
const DEBUG_MODE_MSG = {
	"key": "debug_mode",
	"text": "Debug Mode"
}

@onready var context_menu: PopupMenu = $ContextMenu
@onready var state_node_context_menu: PopupMenu = $StateNodeContextMenu
@onready var convert_to_state_confirmation: ConfirmationDialog = $ConvertToStateConfirmation
@onready var save_dialog: ConfirmationDialog = $SaveDialog
@onready var create_new_state_machine_container: MarginContainer = $MarginContainer
@onready var create_new_state_machine: Button = $MarginContainer/CreateNewStateMachine
@onready var param_panel: Control = $ParametersPanel

var path_viewer: HBoxContainer = HBoxContainer.new()
var condition_visibility: TextureButton = TextureButton.new()
var unsaved_indicator: Label = Label.new()
var message_box: VBoxContainer = VBoxContainer.new()
var editor_accent_color: Color = Color.WHITE
var transition_arrow_icon: Texture2D
var undo_redo: EditorUndoRedoManager
var debug_mode: bool = false:
	set = set_debug_mode
var state_machine_player: Variant:
	set = set_state_machine_player
var state_machine: Variant:
	set = set_state_machine
var can_gui_name_edit: bool = true
var can_gui_context_menu: bool = true

var _reconnecting_connection: Variant
var _last_index: int = 0
var _last_path: String = ""
var _message_box_dict: Dictionary = {}
var _context_node: Variant
var _current_state: String = ""
var _last_stack: Array = []


func _init() -> void:
	super._init()
	
	path_viewer.mouse_filter = MOUSE_FILTER_IGNORE
	path_viewer.set_script(PathViewer)
	path_viewer.dir_pressed.connect(_on_path_viewer_dir_pressed)
	top_bar.add_child(path_viewer)

	condition_visibility.tooltip_text = "Hide/Show Conditions on Transition Line"
	condition_visibility.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	condition_visibility.toggle_mode = true
	condition_visibility.size_flags_vertical = SIZE_SHRINK_CENTER
	condition_visibility.focus_mode = FOCUS_NONE
	condition_visibility.pressed.connect(_on_condition_visibility_pressed)
	condition_visibility.button_pressed = true
	gadget.add_child(condition_visibility)

	unsaved_indicator.size_flags_vertical = SIZE_SHRINK_CENTER
	unsaved_indicator.focus_mode = FOCUS_NONE
	gadget.add_child(unsaved_indicator)

	message_box.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	message_box.grow_vertical = GROW_DIRECTION_BEGIN
	add_child(message_box)

	content.get_child(0).name = "root"

	set_process(false)


func _ready() -> void:
	create_new_state_machine_container.visible = false
	create_new_state_machine.pressed.connect(_on_create_new_state_machine_pressed)
	context_menu.index_pressed.connect(_on_context_menu_index_pressed)
	state_node_context_menu.index_pressed.connect(_on_state_node_context_menu_index_pressed)
	convert_to_state_confirmation.confirmed.connect(_on_convert_to_state_confirmation_confirmed)
	save_dialog.confirmed.connect(_on_save_dialog_confirmed)


func _process(delta: float) -> void:
	if not debug_mode:
		set_process(false)
		return
	if not is_instance_valid(state_machine_player):
		set_process(false)
		set_debug_mode(false)
		return
	var stack: Variant = state_machine_player.get("Members/StackPlayer.gd/stack")
	if ((stack == []) or (stack==null)):
		set_process(false)
		set_debug_mode(false)
		return

	if stack.size() == 1:
		set_current_state(state_machine_player.get("Members/StackPlayer.gd/current"))
	else:
		var stack_max_index: int = stack.size() - 1
		var prev_index: int = stack.find(_current_state)
		if prev_index == -1:
			if _last_stack.size() < stack.size():
				var common_index: int = -1
				for i in _last_stack.size():
					if _last_stack[i] == stack[i]:
						common_index = i
						break
				if common_index > -1:
					var count_from_last_stack: int = _last_stack.size()-1 - common_index -1
					_last_stack.reverse()
					for i in count_from_last_stack:
						set_current_state(_last_stack[i + 1])
					for i in range(common_index + 1, stack.size()):
						set_current_state(stack[i])
				else:
					set_current_state(stack.back())
			else:
				set_current_state(stack.back())
		else:
			var missing_count: int = stack_max_index - prev_index
			for i in range(1, missing_count + 1):
				set_current_state(stack[prev_index + i])
	_last_stack = stack
	var params: Variant = state_machine_player.get("Members/_parameters")
	var local_params: Variant = state_machine_player.get("Members/_local_parameters")
	if params == null:
		params = state_machine_player.get("Members/StateMachinePlayer.gd/_parameters")
		local_params = state_machine_player.get("Members/StateMachinePlayer.gd/_local_parameters")
	param_panel.update_params(params, local_params)
	get_focused_layer(_current_state).debug_update(_current_state, params, local_params)


func _on_path_viewer_dir_pressed(dir: String, index: int) -> void:
	var path: String = path_viewer.select_dir(dir)
	select_layer(get_layer(path))

	if _last_index > index:
		var end_state_parent_path: String = StateMachinePlayer.path_backward(_last_path)
		var end_state_name: String = StateMachinePlayer.path_end_dir(_last_path)
		var layer: Variant = content.get_node_or_null(NodePath(end_state_parent_path))
		if layer:
			var node: Variant = layer.content_nodes.get_node_or_null(NodePath(end_state_name))
			if node:
				var cond_1: bool = (not ("states" in node.state)) or (node.state.states=={})
				var nested_layer: Variant = content.get_node_or_null(NodePath(_last_path))
				var cond_2: bool = (nested_layer.content_nodes.get_node_or_null(NodePath(State.ENTRY_STATE)) == null)
				var cond_3: bool = (nested_layer.content_nodes.get_node_or_null(NodePath(State.EXIT_STATE)) == null)
				if (cond_1 and cond_2 and cond_3):
					convert_to_state(layer, node)

	_last_index = index
	_last_path = path


func _on_context_menu_index_pressed(index: int) -> void:
	var new_node: Control = StateNode.instantiate()
	new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color
	match index:
		0:
			var default_new_state_name: String = "State"
			var state_dup_index: int = 0
			var new_name: String = default_new_state_name
			for state_name in current_layer.state_machine.states:
				if (state_name == new_name):
					state_dup_index += 1
					new_name = "%s%s" % [default_new_state_name, state_dup_index]
			new_node.name = new_name
		1:
			if State.ENTRY_STATE in current_layer.state_machine.states:
				push_warning("Entry node already exist")
				return
			new_node.name = State.ENTRY_STATE
		2:
			if State.EXIT_STATE in current_layer.state_machine.states:
				push_warning("Exit node already exist")
				return
			new_node.name = State.EXIT_STATE
	new_node.position = content_position(get_local_mouse_position())
	add_node(current_layer, new_node)


func _on_state_node_context_menu_index_pressed(index: int) -> void:
	if not _context_node:
		return

	match index:
		0:
			_copying_nodes = [_context_node]
			_context_node = null
		1:
			duplicate_nodes(current_layer, [_context_node])
			_context_node = null
		2:
			remove_node(current_layer, _context_node.name)
			for connection_pair in current_layer.get_connection_list():
				if connection_pair.from == _context_node.name or connection_pair.to == _context_node.name:
					disconnect_node(current_layer, connection_pair.from, connection_pair.to).queue_free()
			_context_node = null
		3:
			_context_node = null
		4:
			convert_to_state_confirmation.popup_centered()


func _on_convert_to_state_confirmation_confirmed() -> void:
	convert_to_state(current_layer, _context_node)
	_context_node.queue_redraw()
	var path: String = str(path_viewer.get_cwd(), "/", _context_node.name)
	var layer: Variant = get_layer(path)
	if layer:
		layer.queue_free()
	_context_node = null


func _on_save_dialog_confirmed() -> void:
	save()


func _on_create_new_state_machine_pressed() -> void:
	var new_state_machine: StateMachine = StateMachine.new()
	
	undo_redo.create_action("Create New StateMachine")
	
	undo_redo.add_do_reference(new_state_machine)
	undo_redo.add_do_property(state_machine_player, "state_machine", new_state_machine)
	undo_redo.add_do_method(self, "set_state_machine", new_state_machine)
	undo_redo.add_do_property(create_new_state_machine_container, "visible", false)
	undo_redo.add_do_method(self, "check_has_entry")
	undo_redo.add_do_method(self, "emit_signal", "inspector_changed", "state_machine")
	
	undo_redo.add_undo_property(state_machine_player, "state_machine", null)
	undo_redo.add_undo_method(self, "set_state_machine", null)
	undo_redo.add_undo_property(create_new_state_machine_container, "visible", true)
	undo_redo.add_undo_method(self, "check_has_entry")
	undo_redo.add_undo_method(self, "emit_signal", "inspector_changed", "state_machine")
	
	undo_redo.commit_action()


func _on_condition_visibility_pressed() -> void:
	for line in current_layer.content_lines.get_children():
		line.vbox.visible = condition_visibility.button_pressed


func _on_debug_mode_changed(new_debug_mode: bool) -> void:
	if new_debug_mode:
		param_panel.show()
		add_message(DEBUG_MODE_MSG.key, DEBUG_MODE_MSG.text)
		set_process(true)
		can_gui_select_node = false
		can_gui_delete_node = false
		can_gui_connect_node = false
		can_gui_name_edit = false
		can_gui_context_menu = false
	else:
		param_panel.clear_params()
		param_panel.hide()
		remove_message(DEBUG_MODE_MSG.key)
		set_process(false)
		can_gui_select_node = true
		can_gui_delete_node = true
		can_gui_connect_node = true
		can_gui_name_edit = true
		can_gui_context_menu = true


func _on_state_machine_player_changed(new_state_machine_player: Variant) -> void:
	if not state_machine_player:
		return
	if new_state_machine_player.get_class() == "EditorDebuggerRemoteObjects":
		return

	if new_state_machine_player:
		create_new_state_machine_container.visible = !new_state_machine_player.state_machine
	else:
		create_new_state_machine_container.visible = false


func _on_state_machine_changed(new_state_machine: Variant) -> void:
	var root_layer: Variant = get_layer("root")
	path_viewer.select_dir("root")
	select_layer(root_layer)
	clear_graph(root_layer)
	for child in root_layer.get_children():
		if child is FlowChartLayer:
			root_layer.remove_child(child)
			child.queue_free()
	if new_state_machine:
		root_layer.state_machine = state_machine
		var validated: bool = StateMachine.validate(new_state_machine)
		if validated:
			print_debug("gd-YAFSM: Corrupted StateMachine Resource fixed, save to apply the fix.")
		draw_graph(root_layer)
		check_has_entry()


func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed and can_gui_context_menu:
					context_menu.set_item_disabled(1, current_layer.state_machine.has_entry())
					context_menu.set_item_disabled(2, current_layer.state_machine.has_exit())
					context_menu.position = get_window().position + Vector2i(get_viewport().get_mouse_position())
					context_menu.popup()


func _input(event: InputEvent) -> void:
	if visible:
		if event is InputEventKey:
			match event.keycode:
				KEY_S:
					if event.ctrl_pressed and event.pressed:
						save_request()


func create_layer(node: Control) -> Variant:
	var new_state_machine: StateMachine = convert_to_state_machine(current_layer, node)
	var parent_path: String = path_viewer.get_cwd()
	var path: String = str(parent_path, "/", node.name)
	var layer: Variant = get_layer(path)
	path_viewer.add_dir(node.state.name)
	if not layer:
		layer = add_layer_to(get_layer(parent_path))
		layer.name = node.state.name
		layer.state_machine = new_state_machine
		draw_graph(layer)
	_last_index = path_viewer.get_child_count()-1
	_last_path = path
	return layer


func open_layer(path: String) -> Variant:
	var dir: StateDirectory = StateDirectory.new(path)
	dir.goto(dir.get_end_index())
	dir.back()
	var next_layer: Variant = get_next_layer(dir, get_layer("root"))
	select_layer(next_layer)
	return next_layer


func get_next_layer(dir: StateDirectory, base_layer: Variant) -> Variant:
	var next_layer: Variant = base_layer
	var np: String = dir.next()
	if np:
		next_layer = base_layer.get_node_or_null(NodePath(np))
		if next_layer:
			next_layer = get_next_layer(dir, next_layer)
		else:
			var to_dir: StateDirectory = StateDirectory.new(dir.get_current())
			to_dir.goto(to_dir.get_end_index())
			to_dir.back()
			var node: Variant = base_layer.content_nodes.get_node_or_null(NodePath(to_dir.get_current_end()))
			next_layer = get_next_layer(dir, create_layer(node))
	return next_layer


func get_focused_layer(state: String) -> Variant:
	var current_dir: StateDirectory = StateDirectory.new(state)
	current_dir.goto(current_dir.get_end_index())
	current_dir.back()
	return get_layer(str("root/", current_dir.get_current()))


func _on_state_node_gui_input(event: InputEvent, node: Control) -> void:
	if node.state.is_entry() or node.state.is_exit():
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					if event.double_click:
						if node.name_edit.get_rect().has_point(event.position) and can_gui_name_edit:
							node.enable_name_edit(true)
							accept_event()
						else:
							var layer: Variant = create_layer(node)
							select_layer(layer)
							accept_event()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_context_node = node
					state_node_context_menu.position = get_window().position + Vector2i(get_viewport().get_mouse_position())
					state_node_context_menu.popup()
					state_node_context_menu.set_item_disabled(4, not (node.state is StateMachine))
					accept_event()


func convert_to_state_machine(layer: Variant, node: Control) -> StateMachine:
	var new_state_machine: StateMachine
	if node.state is StateMachine:
		new_state_machine = node.state
	else:
		new_state_machine = StateMachine.new()
		new_state_machine.name = node.state.name
		new_state_machine.graph_offset = node.state.graph_offset
		layer.state_machine.remove_state(node.state.name)
		layer.state_machine.add_state(new_state_machine)
		node.state = new_state_machine
	return new_state_machine


func convert_to_state(layer: Variant, node: Control) -> State:
	var new_state: State
	if node.state is StateMachine:
		new_state = State.new()
		new_state.name = node.state.name
		new_state.graph_offset = node.state.graph_offset
		layer.state_machine.remove_state(node.state.name)
		layer.state_machine.add_state(new_state)
		node.state = new_state
	else:
		new_state = node.state
	return new_state


func create_layer_instance() -> Control:
	var layer: Control = Control.new()
	layer.set_script(StateMachineEditorLayer)
	layer.editor_accent_color = editor_accent_color
	return layer


func create_line_instance() -> Control:
	var line: Control = TransitionLine.instantiate()
	line.theme.get_stylebox("focus", "FlowChartLine").shadow_color = editor_accent_color
	line.theme.set_icon("arrow", "FlowChartLine", transition_arrow_icon)
	return line


func save_request() -> void:
	if not can_save():
		return

	save_dialog.dialog_text = "Saving StateMachine to %s" % state_machine.resource_path
	save_dialog.popup_centered()


func save() -> void:
	if not can_save():
		return
	
	unsaved_indicator.text = ""
	ResourceSaver.save(state_machine, state_machine.resource_path)


func clear_graph(layer: Variant) -> void:
	clear_connections()
	
	for child in layer.content_nodes.get_children():
		if child is StateNodeScript:
			layer.content_nodes.remove_child(child)
			child.queue_free()
	
	queue_redraw()
	unsaved_indicator.text = ""


func draw_graph(layer: Variant) -> void:
	for state_key in layer.state_machine.states.keys():
		var state: State = layer.state_machine.states[state_key]
		var new_node: Control = StateNode.instantiate()
		new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color
		new_node.name = state_key
		add_node(layer, new_node)
		new_node.state = state
		new_node.state.name = state_key
		new_node.position = state.graph_offset
	for state_key in layer.state_machine.states.keys():
		var from_transitions: Variant = layer.state_machine.transitions.get(state_key)
		if from_transitions:
			for transition in from_transitions.values():
				connect_node(layer, transition.from, transition.to)
				layer._connections[transition.from][transition.to].line.transition = transition
	queue_redraw()
	unsaved_indicator.text = ""


func add_message(key: String, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	_message_box_dict[key] = label
	message_box.add_child(label)
	return label


func remove_message(key: String) -> bool:
	var control: Variant = _message_box_dict.get(key)
	if control:
		_message_box_dict.erase(key)
		message_box.remove_child(control)
		message_box.grow_vertical = GROW_DIRECTION_END
		message_box.grow_vertical = GROW_DIRECTION_BEGIN
		return true
	return false

func check_has_entry() -> void:
	if not current_layer.state_machine:
		return
	if not current_layer.state_machine.has_entry():
		if not (ENTRY_STATE_MISSING_MSG.key in _message_box_dict):
			add_message(ENTRY_STATE_MISSING_MSG.key, ENTRY_STATE_MISSING_MSG.text)
	else:
		if ENTRY_STATE_MISSING_MSG.key in  _message_box_dict:
			remove_message(ENTRY_STATE_MISSING_MSG.key)


func check_has_exit() -> void:
	if not current_layer.state_machine:
		return
	if not path_viewer.get_cwd() == "root":
		if not current_layer.state_machine.has_exit():
			if not (EXIT_STATE_MISSING_MSG.key in _message_box_dict):
				add_message(EXIT_STATE_MISSING_MSG.key, EXIT_STATE_MISSING_MSG.text)
			return
	if EXIT_STATE_MISSING_MSG.key in _message_box_dict:
		remove_message(EXIT_STATE_MISSING_MSG.key)


func _on_layer_selected(layer: Variant) -> void:
	if layer:
		layer.show_content()
		check_has_entry()
		check_has_exit()


func _on_layer_deselected(layer: Variant) -> void:
	if layer:
		layer.hide_content()


func _on_node_dragged(layer: Variant, node: Control, dragged: Vector2) -> void:
	node.state.graph_offset = node.position
	_on_edited()


func _on_node_added(layer: Variant, new_node: Control) -> void:
	while String(new_node.name).begins_with("@"):
		new_node.name = String(new_node.name).lstrip("@")
	
	new_node.undo_redo = undo_redo
	new_node.state.name = new_node.name
	new_node.state.graph_offset = new_node.position
	new_node.name_edit_entered.connect(_on_node_name_edit_entered.bind(new_node))
	new_node.gui_input.connect(_on_state_node_gui_input.bind(new_node))
	layer.state_machine.add_state(new_node.state)
	check_has_entry()
	check_has_exit()
	_on_edited()


func _on_node_removed(layer: Variant, node_name: String) -> void:
	var path: String = str(path_viewer.get_cwd(), "/", node_name)
	var layer_to_remove: Variant = get_layer(path)
	if layer_to_remove:
		layer_to_remove.get_parent().remove_child(layer_to_remove)
		layer_to_remove.queue_free()
	layer.state_machine.remove_state(node_name)
	check_has_entry()
	check_has_exit()
	_on_edited()


func _on_node_connected(layer: Variant, from: String, to: String) -> void:
	if _reconnecting_connection:
		if is_instance_valid(_reconnecting_connection.from_node) and \
		_reconnecting_connection.from_node.name == from and \
		is_instance_valid(_reconnecting_connection.to_node) and \
		_reconnecting_connection.to_node.name == to:
			_reconnecting_connection = null
			return
	if layer.state_machine.transitions.has(from):
		if layer.state_machine.transitions[from].has(to):
			return

	var line: Variant = layer._connections[from][to].line
	var new_transition: Transition = Transition.new(from, to)
	line.transition = new_transition
	layer.state_machine.add_transition(new_transition)
	clear_selection()
	select(line)
	_on_edited()


func _on_node_disconnected(layer: Variant, from: String, to: String) -> void:
	layer.state_machine.remove_transition(from, to)
	_on_edited()


func _on_node_reconnect_begin(layer: Variant, from: String, to: String) -> void:
	_reconnecting_connection = layer._connections[from][to]
	layer.state_machine.remove_transition(from, to)


func _on_node_reconnect_end(layer: Variant, from: String, to: String) -> void:
	var transition: Transition = _reconnecting_connection.line.transition
	transition.to = to
	layer.state_machine.add_transition(transition)
	clear_selection()
	select(_reconnecting_connection.line)


func _on_node_reconnect_failed(layer: Variant, from: String, to: String) -> void:
	var transition: Transition = _reconnecting_connection.line.transition
	layer.state_machine.add_transition(transition)
	clear_selection()
	select(_reconnecting_connection.line)


func _request_connect_from(layer: Variant, from: String) -> bool:
	if from == State.EXIT_STATE:
		return false
	return true


func _request_connect_to(layer: Variant, to: String) -> bool:
	if to == State.ENTRY_STATE:
		return false
	return true


func _on_duplicated(layer: Variant, old_nodes: Array, new_nodes: Array) -> void:
	for i in old_nodes.size():
		var from_node: Control = old_nodes[i]
		for connection_pair in get_connection_list():
			if from_node.name == connection_pair.from:
				for j in old_nodes.size():
					var to_node: Control = old_nodes[j]
					if to_node.name == connection_pair.to:
						var old_connection: Variant = layer._connections[connection_pair.from][connection_pair.to]
						var new_connection: Variant = layer._connections[new_nodes[i].name][new_nodes[j].name]
						for condition in old_connection.line.transition.conditions.values():
							new_connection.line.transition.add_condition(condition.duplicate())
	_on_edited()


func _on_node_name_edit_entered(new_name: String, node: Control) -> void:
	var old: String = node.state.name
	var new: String = new_name
	if old == new:
		return
	if "/" in new or "\\" in new:
		push_warning("Illegal State Name: / and \\ are not allowed in State name(%s)" % new)
		node.name_edit.text = old
		return

	if current_layer.state_machine.change_state_name(old, new):
		rename_node(current_layer, node.name, new)
		node.name = new
		var path: String = str(path_viewer.get_cwd(), "/", node.name)
		var layer: Variant = get_layer(path)
		if layer:
			layer.name = new
		for child in path_viewer.get_children():
			if child.text == old:
				child.text = new
				break
		_on_edited()
	else:
		node.name_edit.text = old


func _on_edited() -> void:
	unsaved_indicator.text = "*"


func _on_remote_transited(from: String, to: String) -> void:
	var from_dir: StateDirectory = StateDirectory.new(from)
	var to_dir: StateDirectory = StateDirectory.new(to)
	var focused_layer: Variant = get_focused_layer(from)
	if from:
		if focused_layer:
			focused_layer.debug_transit_out(from, to)
	if to:
		if from_dir.is_nested() and from_dir.is_exit():
			if focused_layer:
				var path: String = path_viewer.back()
				select_layer(get_layer(path))
		elif to_dir.is_nested():
			if to_dir.is_entry() and focused_layer:
				to_dir.goto(to_dir.get_end_index())
				to_dir.back()
				var node: Variant = focused_layer.content_nodes.get_node_or_null(NodePath(to_dir.get_current_end()))
				if node:
					var layer: Variant = create_layer(node)
					select_layer(layer)
		elif from_dir.is_nested() and not from_dir.is_exit():
			if to_dir._dirs.size() != from_dir._dirs.size():
				to_dir.goto(to_dir.get_end_index())
				var n: String = to_dir.back()
				if not n:
					n = "root"
				var layer: Variant = get_layer(n)
				path_viewer.select_dir(layer.name)
				select_layer(layer)

		focused_layer = get_focused_layer(to)
		if not focused_layer:
			focused_layer = open_layer(to)
		focused_layer.debug_transit_in(from, to)


func can_save() -> bool:
	if not state_machine:
		return false
	var resource_path: String = state_machine.resource_path
	if resource_path.is_empty():
		return false
	if ".scn" in resource_path or ".tscn" in resource_path:
		return false
	return true


func set_debug_mode(v: bool) -> void:
	if debug_mode != v:
		debug_mode = v
		_on_debug_mode_changed(v)
		emit_signal("debug_mode_changed", debug_mode)


func set_state_machine_player(smp: Variant) -> void:
	if state_machine_player != smp:
		state_machine_player = smp
		_on_state_machine_player_changed(smp)


func set_state_machine(sm: Variant) -> void:
	if state_machine != sm:
		state_machine = sm
		_on_state_machine_changed(sm)


func set_current_state(v: String) -> void:
	if _current_state != v:
		var from: String = _current_state
		var to: String = v
		_current_state = v
		_on_remote_transited(from, to)
