class_name MyControl
extends Control

signal change_common
signal regen_images
signal change_num_particles

@onready var beta_slider : MySlider = $BetaSlider
@onready var r_max_slider : MySlider = $RMaxSlider
@onready var n_color_slider : MySlider = $ColorSlider
@onready var num_part_slider : MySlider = $NumPartSlider
@onready var dt_slider : MySlider = $DtSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	beta_slider.setup(
		"beta:",
		0.01,
		0.01,
		1.0,
		Common.beta,
		"%1.2f")
	r_max_slider.setup(
		"r_max:",
		0.01,
		0.01,
		1.0,
		Common.r_max,
		"%1.2f")
	n_color_slider.setup(
		"colors:",
		1,
		1,
		16,
		Common.n_color,
		"%d")
	num_part_slider.setup(
		"n_parts:",
		100,
		1000,
		Common.grid_size * Common.grid_size,
		Common.num_particles,
		"%d"
	)
	dt_slider.setup(
		"dtime:",
		0.01,
		0.01,
		2.00,
		Common.dt,
		"%1.2f"
	)

func _on_beta_slider_change_value(value):
	Common.beta = value
	change_common.emit()


func _on_r_max_slider_change_value(value):
	Common.r_max = value
	change_common.emit()


func _on_color_slider_change_value(value):
	Common.n_color = value
	regen_images.emit()

func _on_num_part_slider_change_value(value):
	Common.num_particles = value
	change_num_particles.emit()


func _on_dt_slider_change_value(value):
	Common.dt = value
	change_common.emit()
