extends Node2D

var rd = RenderingServer.create_local_rendering_device()

# Image information used to pass data from computer shader to particle shader
var image_size : Vector2i = Vector2i(Common.data_texture_size, Common.data_texture_size)
var n_pixels : int = image_size.x * image_size.y

var shader_executed = false

class ShaderResource:
	var image: Image
	var image_data: PackedByteArray
	var texture: ImageTexture
	var buffer: RID
	var uniform : RDUniform
	var fmt : RDTextureFormat
	var w : int
	var h : int
	func _init(width, height):
		self.w = width;
		self.h = height;
		self.image = Image.create(self.w, self.h, false, Image.FORMAT_RGBAF)
	func _fill_image_pixels():
		var n_color = Common.n_color-1
		if n_color == 0:
			n_color = 1
		for i in Common.grid_size:
			for j in Common.grid_size:
				var col = Color(randf(), randf(), float(randi_range(0, n_color)) / n_color)
				self.image.set_pixel(i, j, col)
	func _setup_texture():
		self.texture = ImageTexture.create_from_image(self.image)
	func _read_buffer(rd: RenderingDevice):
		self.image_data = rd.texture_get_data(self.buffer, 0)
		self.image = Image.create_from_data(self.w, self.h, false, Image.FORMAT_RGBAF, self.image_data)
		self._update_texture()
	func _update_texture():
		self.texture.update(self.image)
	func _create_uniform(rd: RenderingDevice, _fmt: RDTextureFormat, bid: int):
		self.buffer = rd.texture_create(_fmt, RDTextureView.new(), [self.image.get_data()])
		self.uniform = RDUniform.new()
		self.uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		self.uniform.binding = bid
		self.uniform.add_id(self.buffer)
		self.fmt = _fmt
	func _update_uniform(rd: RenderingDevice):
		self.uniform.clear_ids()
		rd.texture_update(self.buffer, 0, self.image.get_data())
		self.uniform.add_id(self.buffer)

# Shader Resources (Image/Textures/Buffers)
var p1_data : ShaderResource # position and color
var p2_data : ShaderResource # rg: velocity
var p3_data : ShaderResource # position and color
var force_matrix : ShaderResource

var params_uniform: RDUniform

var shader : RID
var pipeline : RID
var uniform_set : RID
var bindings : Array

func _gen_matrix():
	for i in range(Common.n_color):
		for j in range(Common.n_color):
			var col = Color(randf()-.5, 1, 1, 1)
			force_matrix.image.set_pixel(i, j, col)

func _create_shader(shader_filename):
	var shader_file = load(shader_filename)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	return rd.shader_create_from_spirv(shader_spirv)

func _init_images():
	p1_data = ShaderResource.new(image_size.x, image_size.y)
	p1_data._fill_image_pixels()
	p1_data._setup_texture()
	p2_data = ShaderResource.new(image_size.x, image_size.y)
	p2_data._setup_texture()
	p3_data = ShaderResource.new(image_size.x, image_size.y)
	p3_data.image = p1_data.image
	p3_data._setup_texture()
	force_matrix = ShaderResource.new(image_size.x, image_size.y)
	_gen_matrix()
	force_matrix._setup_texture()

func _create_params_buffer(delta):
	var params_buffer_bytes : PackedByteArray = PackedFloat32Array(
		[
			Common.num_particles,
			Common.grid_size,
			Common.r_max,
			Common.get_friction_factor(),
			Common.beta,
			Common.dt * 0.1,
			Common.n_color,
			delta
		]).to_byte_array()
	return rd.storage_buffer_create(params_buffer_bytes.size(), params_buffer_bytes)
	
func _setup_shader_uniforms():
	var params_buffer = _create_params_buffer(0)
	params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 0
	params_uniform.add_id(params_buffer)
	
	var fmt = RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	# Create Uniforms
	p1_data._create_uniform(rd, fmt, 1)
	p2_data._create_uniform(rd, fmt, 2)
	p3_data._create_uniform(rd, fmt, 3)
	force_matrix._create_uniform(rd, fmt, 4)
	_set_binding_array(0)

func _execute_shader():
	uniform_set = rd.uniform_set_create(bindings, shader, 0)
	pipeline = rd.compute_pipeline_create(shader)
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# work_group_x_size = should be num_particles / local_size_x
	var work_group_size = 1
	if Common.num_particles > Common.local_size_x:
		work_group_size = Common.num_particles / Common.local_size_x
		if int(Common.num_particles) % Common.local_size_x > 0:
			work_group_size += 1
	rd.compute_list_dispatch(compute_list, work_group_size, 1, 1)
	rd.compute_list_end()
	rd.submit()
	shader_executed = true
	
	
func _set_binding_array(delta):
	params_uniform.clear_ids()
	params_uniform.add_id(_create_params_buffer(delta))
	bindings = [
		params_uniform,
		p1_data.uniform,
		p2_data.uniform,
		p3_data.uniform,
		force_matrix.uniform
	]

# Called when the node enters the scene tree for the first time.
func _ready():
	_init_images()
	_gen_matrix()
	force_matrix._setup_texture()
	$ParticlesGPU.amount = Common.num_particles
	$ParticlesGPU.process_material.set_shader_parameter("part_data_tex", p1_data.texture)
	$ParticlesGPU.process_material.set_shader_parameter("num_particles", Common.num_particles)
	$ParticlesGPU.process_material.set_shader_parameter("grid_size", Common.grid_size)
	shader = _create_shader("res://compute.glsl")
	_setup_shader_uniforms()
	_execute_shader()

var run_shader = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shader_executed:
		rd.sync()
		shader_executed = false
	if run_shader:
		p1_data._read_buffer(rd) # read the data from the compute shader to update the texture
		_set_binding_array(delta)
		_execute_shader()
	if Input.is_action_just_pressed("change_matrix"):
			_gen_matrix()
			force_matrix._update_uniform(rd)
	var vp_size = get_viewport_rect().size
	$ParticlesGPU.process_material.set_shader_parameter("vw_size", vp_size)
	$ParticlesGPU.process_material.set_shader_parameter("scale", Common.scale)
	$CanvasLayer/Label.text = "FPS: %d - Particles: %d" % [Engine.get_frames_per_second(), Common.num_particles]
	
func _on_control_change_common():
	pass # Replace with function body.

func _gen_new_image():
	# wait for the current execution to finish
	rd.sync()
	shader_executed = false
	_gen_matrix()
	force_matrix._update_uniform(rd)
	p1_data._fill_image_pixels()
	p1_data._update_texture()
	p1_data._update_uniform(rd)
	$ParticlesGPU.process_material.set_shader_parameter("part_data_tex", p1_data.texture)
	run_shader = true
	
func _on_control_regen_images():
	run_shader = false
	_gen_new_image()

func _on_control_change_num_particles():
	$ParticlesGPU.amount = Common.num_particles

func _on_control_regen_matrix():
	rd.sync()
	shader_executed = false
	_gen_matrix()
	force_matrix._update_uniform(rd)
	run_shader = true
