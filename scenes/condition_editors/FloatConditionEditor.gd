@tool
extends "ValueConditionEditor.gd"


@onready var float_value: LineEdit = $MarginContainer/FloatValue

var _old_value: float = 0.0


func _ready() -> void:
	super._ready()
	
	float_value.text_submitted.connect(_on_float_value_text_submitted)
	float_value.focus_entered.connect(_on_float_value_focus_entered)
	float_value.focus_exited.connect(_on_float_value_focus_exited)
	set_process_input(false)


func _input(event: InputEvent) -> void:
	super._input(event)
	
	if event is InputEventMouseButton:
		if event.pressed:
			if get_viewport().gui_get_focus_owner() == float_value:
				var local_event: InputEvent = float_value.make_input_local(event)
				if not float_value.get_rect().has_point(local_event.position):
					float_value.release_focus()


func _on_value_changed(new_value: Variant) -> void:
	float_value.text = str(snapped(new_value, 0.01)).pad_decimals(2)


func _on_float_value_text_submitted(new_text: String) -> void:
	change_value_action(_old_value, float(new_text))
	float_value.release_focus()


func _on_float_value_focus_entered() -> void:
	set_process_input(true)
	_old_value = float(float_value.text)


func _on_float_value_focus_exited() -> void:
	set_process_input(false)
	change_value_action(_old_value, float(float_value.text))


func _on_condition_changed(new_condition: Variant) -> void:
	super._on_condition_changed(new_condition)
	if new_condition:
		float_value.text = str(snapped(new_condition.value, 0.01)).pad_decimals(2)
