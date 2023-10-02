extends Control

signal change_common
signal regen_images
signal change_num_particles
signal regen_matrix

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sliders.hide()

func _on_show_config_pressed():
	$ShowConfig.hide()
	$Sliders.show()

func _on_hide_config_pressed():
	$ShowConfig.show()
	$Sliders.hide()

func _on_sliders_change_common():
	change_common.emit()

func _on_sliders_regen_images():
	regen_images.emit()


func _on_sliders_change_num_particles():
	change_num_particles.emit()


func _on_regen_matrix_pressed():
	regen_matrix.emit()
