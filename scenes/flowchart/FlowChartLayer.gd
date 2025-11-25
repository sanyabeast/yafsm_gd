@tool
extends Control


const FlowChartNode = preload("res://addons/yafsm/scenes/flowchart/FlowChartNode.gd")

var content_lines: Control = Control.new()
var content_nodes: Control = Control.new()
var _connections: Dictionary = {}


func _init() -> void:
	name = "FlowChartLayer"
	mouse_filter = MOUSE_FILTER_IGNORE

	content_lines.name = "content_lines"
	content_lines.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content_lines)
	move_child(content_lines, 0)

	content_nodes.name = "content_nodes"
	content_nodes.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content_nodes)


func hide_content() -> void:
	content_nodes.hide()
	content_lines.hide()


func show_content() -> void:
	content_nodes.show()
	content_lines.show()


func get_scroll_rect(scroll_margin: float = 0.0) -> Rect2:
	var rect: Rect2 = Rect2()
	for child in content_nodes.get_children():
		var child_rect: Rect2 = child.get_rect()
		rect = rect.merge(child_rect)
	return rect.grow(scroll_margin)


func add_node(node: Node) -> void:
	content_nodes.add_child(node)


func remove_node(node: Node) -> void:
	if node:
		content_nodes.remove_child(node)


func _connect_node(connection: Connection) -> void:
	content_lines.add_child(connection.line)
	connection.join()


func _disconnect_node(connection: Connection) -> Control:
	content_lines.remove_child(connection.line)
	return connection.line


func rename_node(old: String, new: String) -> void:
	for from in _connections.keys():
		if from == old:
			var from_connections: Dictionary = _connections[from]
			_connections.erase(old)
			_connections[new] = from_connections
		else:
			for to in _connections[from].keys():
				if to == old:
					var from_connection: Dictionary = _connections[from]
					var value: Connection = from_connection[old]
					from_connection.erase(old)
					from_connection[new] = value


func connect_node(line: Control, from: String, to: String, interconnection_offset: int = 0) -> void:
	if from == to:
		return
	var connections_from: Variant = _connections.get(from)
	if connections_from:
		if to in connections_from:
			return
	var connection: Connection = Connection.new(line, content_nodes.get_node(NodePath(from)), content_nodes.get_node(NodePath(to)))
	if connections_from == null:
		connections_from = {}
		_connections[from] = connections_from
	connections_from[to] = connection
	_connect_node(connection)

	connections_from = _connections.get(to)
	if connections_from:
		var inv_connection: Variant = connections_from.get(from)
		if inv_connection:
			connection.offset = interconnection_offset
			inv_connection.offset = interconnection_offset
			connection.join()
			inv_connection.join()


func disconnect_node(from: String, to: String) -> Control:
	var connections_from: Variant = _connections.get(from)
	var connection: Variant = connections_from.get(to)
	if connection == null:
		return

	_disconnect_node(connection)
	if connections_from.size() == 1:
		_connections.erase(from)
	else:
		connections_from.erase(to)

	connections_from = _connections.get(to)
	if connections_from:
		var inv_connection: Variant = connections_from.get(from)
		if inv_connection:
			inv_connection.offset = 0
			inv_connection.join()
	return connection.line


func clear_connections() -> void:
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection.line.queue_free()
	_connections.clear()


func get_connection_list() -> Array:
	var connection_list: Array = []
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection_list.append({"from": connection.from_node.name, "to": connection.to_node.name})
	return connection_list


class Connection:
	var line: Control
	var from_node: Node
	var to_node: Node
	var offset: int = 0


	func _init(p_line: Control, p_from_node: Node, p_to_node: Node) -> void:
		line = p_line
		from_node = p_from_node
		to_node = p_to_node


	func join() -> void:
		line.join(get_from_pos(), get_to_pos(), offset, [from_node.get_rect() if from_node else Rect2(), to_node.get_rect() if to_node else Rect2()])


	func get_from_pos() -> Vector2:
		return from_node.position + from_node.size / 2


	func get_to_pos() -> Vector2:
		return to_node.position + to_node.size / 2 if to_node else line.position
