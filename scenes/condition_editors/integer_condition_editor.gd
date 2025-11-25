@tool
extends "value_condition_editor.gd"


@onready var integer_value: LineEdit = $MarginContainer/IntegerValue

var _old_value: int = 0


func _ready() -> void:
	super._ready()
	
	integer_value.text_submitted.connect(_on_integer_value_text_submitted)
	integer_value.focus_entered.connect(_on_integer_value_focus_entered)
	integer_value.focus_exited.connect(_on_integer_value_focus_exited)
	set_process_input(false)


func _input(event: InputEvent) -> void:
	super._input(event)
	
	if event is InputEventMouseButton:
		if event.pressed:
			if get_viewport().gui_get_focus_owner() == integer_value:
				var local_event: InputEvent = integer_value.make_input_local(event)
				if not integer_value.get_rect().has_point(local_event.position):
					integer_value.release_focus()


func _on_value_changed(new_value: Variant) -> void:
	integer_value.text = str(new_value)


func _on_integer_value_text_submitted(new_text: String) -> void:
	change_value_action(_old_value, int(new_text))
	integer_value.release_focus()


func _on_integer_value_focus_entered() -> void:
	set_process_input(true)
	_old_value = int(integer_value.text)


func _on_integer_value_focus_exited() -> void:
	set_process_input(false)
	change_value_action(_old_value, int(integer_value.text))


func _on_condition_changed(new_condition: Variant) -> void:
	super._on_condition_changed(new_condition)
	if new_condition:
		integer_value.text = str(new_condition.value)
