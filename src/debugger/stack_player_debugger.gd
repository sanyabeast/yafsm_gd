@tool
extends Control


const StackPlayer = preload("../stack_player.gd")
const StackItem = preload("stack_item.tscn")

@onready var Stack: VBoxContainer = $MarginContainer/Stack


func _get_configuration_warnings() -> PackedStringArray:
	if not (get_parent() is StackPlayer):
		return PackedStringArray(["Debugger must be child of StackPlayer"])
	return PackedStringArray()


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	get_parent().pushed.connect(_on_StackPlayer_pushed)
	get_parent().popped.connect(_on_StackPlayer_popped)
	sync_stack()


func _on_set_label(label: Label, obj: Variant) -> void:
	label.text = str(obj)


func _on_StackPlayer_pushed(to: Variant) -> void:
	var stack_item: Control = StackItem.instantiate()
	_on_set_label(stack_item.get_node("Label"), to)
	Stack.add_child(stack_item)
	Stack.move_child(stack_item, 0)


func _on_StackPlayer_popped(from: Variant) -> void:
	sync_stack()


func sync_stack() -> void:
	var diff: int = Stack.get_child_count() - get_parent().stack.size()
	for i in abs(diff):
		if diff < 0:
			var stack_item: Control = StackItem.instantiate()
			Stack.add_child(stack_item)
		else:
			var child: Node = Stack.get_child(0)
			Stack.remove_child(child)
			child.queue_free()
	var stack: Array = get_parent().stack
	for i in stack.size():
		var obj: Variant = stack[stack.size()-1 - i]
		var child: Node = Stack.get_child(i)
		_on_set_label(child.get_node("Label"), obj)
