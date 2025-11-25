@tool
extends MarginContainer


@onready var grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func update_params(params: Dictionary, local_params: Dictionary) -> void:
	for param in grid.get_children():
		if not (param.name in params):
			remove_param(param.name)
	for param in params:
		var value: Variant = params[param]
		if value == null:
			continue
		set_param(param, str(value))


	for param in grid.get_children():
		if not (param.name in local_params) and not (param.name in params):
			remove_param(param.name)
	for param in local_params:
		var nested_params: Dictionary = local_params[param]
		for nested_param in nested_params:
			var value: Variant = nested_params[nested_param]
			if value == null:
				continue
			set_param(str(param, "/", nested_param), str(value))


func set_param(param: String, value: String) -> void:
	var label: Label = grid.get_node_or_null(NodePath(param))
	if not label:
		label = Label.new()
		label.name = param
		grid.add_child(label)

	label.text = "%s = %s" % [param, value]


func remove_param(param: String) -> void:
	var label: Node = grid.get_node_or_null(NodePath(param))
	if label:
		grid.remove_child(label)
		label.queue_free()
		set_anchors_preset(PRESET_BOTTOM_RIGHT)


func clear_params() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()


func _on_button_pressed() -> void:
	grid.visible = !grid.visible
	if grid.visible:
		button.text = "Hide params"
	else:
		button.text = "Show params"
	
	set_anchors_preset(PRESET_BOTTOM_RIGHT)
