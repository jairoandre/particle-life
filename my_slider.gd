class_name MySlider
extends Control

signal change_value

var format = "%s"

var submit_on_change = false

func setup(label, step, min_value, max_value, init_value, fmt):
	$Slider.step = step
	$Slider.min_value = min_value
	$Slider.max_value = max_value
	$Slider.value = init_value
	format = fmt
	$Label.text = label
	$Value.text = format % init_value
	submit_on_change = true

func _on_slider_drag_ended(value_changed):
	if value_changed:
		change_value.emit($Slider.value)
	submit_on_change = true


func _on_slider_drag_started():
	submit_on_change = false

func _on_slider_value_changed(value):
	$Value.text = format % value
	if submit_on_change:
		change_value.emit($Slider.value)
