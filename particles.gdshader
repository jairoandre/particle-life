shader_type particles;

uniform vec2 vw_size;
uniform sampler2D part_data_tex; // r xpos, g ypos, b color
uniform float scale;
uniform int grid_size;
uniform int num_particles;

vec3 hsv2rgb(float h) {
	vec3 c = vec3(h * 0.95, 1., 1.);
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void process() {
	int image_size = textureSize(part_data_tex,0).x; // 512px
//	if (int(INDEX) >= num_particles) {
//		// to avoid to print particles that
//		COLOR = vec4(0);
//	} else {
		int i = int(mod(float(INDEX),float(grid_size)));
		int j = int(INDEX/uint(grid_size));
		vec4 part_data = texelFetch(part_data_tex, ivec2(i, j), 0);
		TRANSFORM[3] = vec4(part_data.r * vw_size.r, part_data.g * vw_size.g, 0., 0.);
		
		mat2 scale_mat = mat2(vec2(scale, 0.), vec2(0., scale));
		TRANSFORM[0].xy = scale_mat[0];
		TRANSFORM[1].xy = scale_mat[1];
		
		// Place process code here.
		COLOR = vec4(hsv2rgb(part_data.b), 1.);
		
//	}
	
	
}
