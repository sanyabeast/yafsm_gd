@tool
extends HBoxContainer


signal dir_pressed(dir: String, index: int)


func _init() -> void:
	add_dir("root")


func back() -> String:
	return select_dir(get_child(max(get_child_count()-1 - 1, 0)).name)


func select_dir(dir: String) -> String:
	for i in get_child_count():
		var child: Node = get_child(i)
		if child.name == dir:
			remove_dir_until(i)
			return get_dir_until(i)
	return ""


func add_dir(dir: String) -> Button:
	var button: Button = Button.new()
	button.name = dir
	button.flat = true
	button.text = dir
	add_child(button)
	button.pressed.connect(_on_button_pressed.bind(button))
	return button


func remove_dir_until(index: int) -> void:
	var to_remove: Array = []
	for i in get_child_count():
		if index == get_child_count()-1 - i:
			break
		var child: Node = get_child(get_child_count()-1 - i)
		to_remove.append(child)
	for n in to_remove:
		remove_child(n)
		n.queue_free()


func get_cwd() -> String:
	return get_dir_until(get_child_count()-1)


func get_dir_until(index: int) -> String:
	var path: String = ""
	for i in get_child_count():
		if i > index:
			break
		var child: Node = get_child(i)
		if i == 0:
			path = "root"
		else:
			path = str(path, "/", child.text)
	return path


func _on_button_pressed(button: Button) -> void:
	var index: int = button.get_index()
	var dir: String = button.name
	emit_signal("dir_pressed", dir, index)
