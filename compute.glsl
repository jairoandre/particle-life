#[compute]
#version 450

layout(local_size_x=1024,local_size_y=1,local_size_z=1)in;

layout(set=0,binding=0,std430)restrict buffer Params{
	float num_particles;
	float grid_size;
	float r_max;
	float friction_factor;
	float beta;
	float dt;
	float n_color;
	float delta;
}params;

layout(rgba32f,binding=1)uniform image2D p1_data;// rg: position / color
layout(rgba32f,binding=2)uniform image2D p2_data;// rg: velocity
layout(rgba32f,binding=3)uniform image2D p3_data;// rg: old position
layout(rgba32f,binding=4)uniform image2D force_matrix;// r: force

ivec2 one_to_two(int index){
	int grid_size=int(params.grid_size);
	int row=int(index/grid_size);
	int col=index%grid_size;
	return ivec2(col,row);
}

float wrap_pos(float o,float t){
	float d=t-o;
	if(d>.5||d<-.5){
		return t<o?t+1.:t-1.;
	}
	return t;
}

float clamp_pos(float v){
	return v>1.?0.:v<0.?1.:v;
}

float force(float r,int col_1,int col_2){
	float beta=params.beta;
	if(r<beta){
		return r/beta-1.;
	}else if(beta<r&&r<1.){
		float f_m=imageLoad(force_matrix,ivec2(col_1,col_2)).r;
		return f_m*(1.-abs(2.*r-1.-beta)/(1.-beta));
	}
	return 0.;
}

void main(){
	int index=int(gl_GlobalInvocationID.x);
	int num_particles=int(params.num_particles);
	if(index>=num_particles){
		// should not change anything
		return;
	}
	ivec2 pos=one_to_two(index);
	vec4 p_data=imageLoad(p1_data,pos);// current position
	vec2 p_pos=p_data.rg;
	int p_col=int(p_data.b*(params.n_color-1.));
	vec2 total_force=vec2(0);
	for(int i=0;i<num_particles;i++){
		vec4 o_data=imageLoad(p3_data,one_to_two(i));
		vec2 o_pos=o_data.rg;
		int o_col=int(o_data.b*params.n_color-1.);
		float wx=wrap_pos(p_pos.x,o_pos.x);
		float wy=wrap_pos(p_pos.y,o_pos.y);
		o_pos=vec2(wx,wy);
		vec2 d_vec=o_pos-p_pos;
		float r=length(d_vec);
		if(r>0.&&r<params.r_max){
			float f=force(r/params.r_max,p_col,o_col);
			total_force+=f*(d_vec/r);
		}
	}
	total_force*=params.r_max;
	vec4 vel_data=imageLoad(p2_data,pos);// current velocity
	vec2 vel=vel_data.rg;
	vel*=params.friction_factor;
	vel+=total_force*params.dt;
	p_pos+=vel*params.delta;
	p_pos.x=clamp_pos(p_pos.x);
	p_pos.y=clamp_pos(p_pos.y);
	vec4 p_data_old=p_data;
	p_data.rg=p_pos;
	vel_data.rg=vel;
	imageStore(p1_data,pos,p_data);
	imageStore(p2_data,pos,vel_data);
	imageStore(p3_data,pos,p_data_old);
}
