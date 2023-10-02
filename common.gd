extends Node

var data_texture_size = 256
var clear_color = Color.BLACK

var dt = 1.0
var local_size_x = 1024
var num_particles = 1024*5
var grid_size = 256
var beta = 0.3
var r_max = 0.1
var friction_half_life = 0.070
var friction_factor = pow(0.5, dt/friction_half_life)
var n_color = 8
var scale = 0.05

func get_friction_factor():
	return pow(0.5, dt/friction_half_life)
