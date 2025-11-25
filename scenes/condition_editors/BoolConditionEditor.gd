@tool
extends "ValueConditionEditor.gd"


@onready var checkbox: CheckButton = $MarginContainer/BooleanValue


func _ready() -> void:
	super._ready()
	
	checkbox.pressed.connect(_on_checkbox_pressed)


func _on_value_changed(new_value: Variant) -> void:
	if checkbox.button_pressed != new_value:
		checkbox.button_pressed = new_value


func _on_checkbox_pressed() -> void:
	change_value_action(condition.value, checkbox.button_pressed)


func _on_condition_changed(new_condition: Variant) -> void:
	super._on_condition_changed(new_condition)
	if new_condition:
		checkbox.button_pressed = new_condition.value
