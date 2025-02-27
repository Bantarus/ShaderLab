#version 330

// Input from vertex shader
in vec2 var_texcoord0;
in vec2 var_frag_coord;

// Output
out vec4 color_out;

// Uniforms
uniform energy_ball_fp {
	vec4 resolution;  // xy: resolution, zw: unused
	vec4 time;        // x: current time in seconds, yzw: unused

	// Ball parameters
	vec4 ball_params;  // x: move_speed, y: padding, z: delay, w: unused
	vec4 distortion;   // x,y: amplitude, z: frequency, w: unused
	vec4 scale;        // x,y: scale, zw: unused

	// Lightning parameters
	vec4 lightning_params1;  // x: num lines, y: spawn_radius, z: spawn_radius_rand, w: node_differ_radius
	vec4 lightning_params2;  // x: differ_rand, y: volt_thickness, z: volt_thickness_rand, w: amplitude
	vec4 lightning_params3;  // x: amplitude_rand, y: oscillation_speed, z: oscillation_rand, w: speed
	vec4 lightning_params4;  // x: angular_speed, y: loop_amount, z: loop_length, w: max_nodes
	vec4 lightning_color;    // xyz: color rgb, w: intensity
};

// Textures
uniform sampler2D texture_sampler0;  // Main texture
uniform sampler2D texture_sampler1;  // Background texture

// Utility functions
float drawLine(vec2 start, vec2 end, vec2 uv, float t_b, float t_e)
{
	vec2 direction = normalize(end-start);
	vec2 uv_to_start = uv-start;
	float projection = clamp(dot(uv_to_start,direction), 0.0, length(end-start));
	vec2 close = start+projection*direction;
	float dist = length(uv-close);
	float thick = t_b + (projection/length(start-end))*(t_e-t_b);
	return smoothstep(thick, thick-0.03, dist);
}

vec3 clamp_dots(vec3 color, float lower, float upper) {
	if(color.x < lower) {
		color.x = 0.0;
	}
	if(color.y < lower) {
		color.y = 0.0;
	}
	if(color.z < lower) {
		color.z = 0.0;
	}
	float avg = (color.x+color.y+color.z)/3.0;
	return vec3(avg, avg, avg);
}

float height(in vec2 uv, in sampler2D tex, in float time) {
	return texture(tex, uv+vec2(time,time)*0.1).x;
}

const vec2 NE = vec2(0.01, 0.0);

vec3 normal(in vec2 uv, in sampler2D tex, in float time) {
	return normalize(vec3(height(uv+NE.xy, tex, time)-height(uv-NE.xy, tex, time),
	0.0,
	height(uv+NE.yx, tex, time)-height(uv-NE.yx, tex, time)));
}

// Main function
void main() {
	// Get fragment coordinates
	vec2 uv = var_frag_coord;

	// Normalize coordinates to [-1, 1] range, centered at (0,0)
	uv = uv * 2.0 - 1.0;

	// Calculate screen aspect ratio
	float screen_ratio = resolution.x / resolution.y;

	// Get texture aspect ratio from the resolution uniform's z component
	float texture_ratio = resolution.z;

	// Apply aspect ratio correction to maintain circular shape
	if (screen_ratio > 1.0) {
		// Landscape: scale x
		uv.x *= screen_ratio;
	} else {
		// Portrait: scale y
		uv.y /= screen_ratio;
	}

	// Correct for non-square texture
	uv.y *= texture_ratio;

	// Parameters
	float padding = ball_params.y;
	float move_speed = ball_params.x;
	float delay = ball_params.z;

	vec2 amp = distortion.xy;
	float frequency = distortion.z;
	vec2 scale_val = scale.xy;

	float t = time.x;
	float compensate = (screen_ratio+padding)/move_speed;
	vec2 ball_position = vec2(
		-screen_ratio-padding+mod((t+compensate-delay)*move_speed, padding*2.0+screen_ratio*2.0), 0.0
	);

	if(t < delay) {
		ball_position = vec2(0.0, 0.0);
	}

	// Background distortion
	vec2 background_distortion_uv = uv;
	background_distortion_uv.x += smoothstep(0.9, 0.6, length(uv - ball_position))*amp.x*cos(frequency*t+uv.y*scale_val.x);
	background_distortion_uv.y += smoothstep(0.9, 0.6, length(uv - ball_position))*amp.y*sin(frequency*t+uv.x*scale_val.y);

	// Adjust UV for texture lookup
	vec2 texCoord = (background_distortion_uv + 1.0) * 0.5;

	vec3 background = texture(texture_sampler1, texCoord).xyz * 0.2;
	vec3 color = background;

	// Lightning parameters
	int num = int(lightning_params1.x);
	float spawn_radius = lightning_params1.y;
	float spawn_radius_rand = lightning_params1.z;
	float node_differ_radius = lightning_params1.w;

	float differ_rand = lightning_params2.x;
	float volt_thickness = lightning_params2.y;
	float volt_thickness_rand = lightning_params2.z;
	float amplitude = lightning_params2.w;

	float amplitude_rand = lightning_params3.x;
	float oscillation_speed = lightning_params3.y;
	float oscillation_rand = lightning_params3.z;
	float speed = lightning_params3.w;

	float angular_speed = lightning_params4.x;
	float loop_amount = lightning_params4.y;
	float loop_length = lightning_params4.z;
	int max_nodes = int(lightning_params4.w);

	vec3 purple = vec3(1.0, 0.9, 1.0) * 0.8;

	vec3 lines = vec3(0.0, 0.0, 0.0);
	float nodes_removal = 4.0;

	int seed_offset = 0;
	for (int i = 0; i < num; i++) {
		if (i >= num) break; // Safety check for some GPU drivers

		float seed = float(i+seed_offset) * 2228.2918;

		float time_offset = fract(sin(seed) * 8927.2357) * loop_length;
		float loop = (t + time_offset) / loop_length;

		seed_offset = int(mod(loop, loop_amount));

		int nodes = int(
			float(max_nodes) -
			fract(sin(seed) * 1227.2212) * nodes_removal
		);

		float angular_speed_i = (fract(sin(seed) * 3452.5881) - 0.5) * 2.0 * angular_speed;
		float angle = angular_speed * t + fract(cos(seed) * 9231.124392843) * 6.2831;

		float dist_to_center = spawn_radius + spawn_radius_rand * fract(sin(seed) * 6248.8572);
		vec2 start = vec2(cos(angle), sin(angle)) * dist_to_center;
		vec2 position = start + ball_position;

		float volt_thickness_i = volt_thickness + fract(sin(seed) * 3789.01241) * volt_thickness_rand;
		float thickness_fall_off = volt_thickness_i/float(nodes);

		for (int j = 0; j < max_nodes; j++) {
			if (j > nodes) break;

			float node_seed = float(num + j + (i * max_nodes)+seed_offset) * 3242.96291079;
			float differ = node_differ_radius + fract(sin(node_seed) * 7452.3967) * differ_rand;

			float osc_speed = oscillation_speed + fract(sin(node_seed) * 3412.4823) * oscillation_rand;
			float amp = amplitude + fract(sin(node_seed) * 2241.6469) * amplitude_rand;
			float age = sin(t * osc_speed);
			vec2 move_dir = vec2(cos(fract(cos(node_seed) * 12569.01435207) * 6.2831), 
			sin(fract(cos(node_seed) * 12569.01435207) * 6.2831));

			vec2 new_position = position +
			vec2(cos(fract(cos(node_seed) * 43758.5453123) * 6.2831),
			sin(fract(cos(node_seed) * 43758.5453123) * 6.2831)) * differ +
			move_dir * speed * age * amp;

			float intensity = 15.0;
			vec3 node_color = vec3(0.3, 0.25, 0.3) * intensity * pow(length(uv-ball_position), 2.0);

			float lifetime_ratio = mod((t + time_offset), loop_length) / loop_length;
			float t_b = volt_thickness_i - (float(j) * thickness_fall_off);
			float t_e = volt_thickness_i - (float(j+1) * thickness_fall_off);

			float t_n = volt_thickness_i - (float(j+2) * thickness_fall_off);
			lines += drawLine(
				position,
				new_position,
				uv,
				t_b,
				t_e
			) * (1.0 - lifetime_ratio) * node_color * 2.0;

			position = new_position + normalize(new_position-position) * t_n;
		}
	}

	float outside_purple_distance = length(uv-ball_position);

	// Outer glow
	float intensity = smoothstep(1.0, 0.4, outside_purple_distance);
	color += vec3(0.15, 0.0, 0.2) * 1.0 * intensity;

	// Inner glow with normal mapping
	vec2 normalUV = (uv - ball_position * 0.5 + 1.0) * 0.5; // Adjust UV for texture lookup
	vec3 norm = normal(normalUV, texture_sampler0, t);
	vec3 lightDir = normalize(vec3(10.0, 15.0, 5.0));
	intensity = smoothstep(0.5, 0.2, outside_purple_distance);
	color += vec3(0.4, 0.1, 0.6) * 1.5 * intensity;

	vec3 dark_spots = (color * max(0.0, dot(lightDir, norm)) * smoothstep(0.5, 0.32, outside_purple_distance)) * length(uv-ball_position);

	vec2 normalUV2 = (uv * 1.0 - ball_position + 1.0) * 0.5; // Adjust UV for texture lookup
	norm = normal(normalUV2, texture_sampler0, t);
	vec3 spots = (color * max(0.0, dot(lightDir, norm)) * smoothstep(0.5, 0.4, outside_purple_distance)) * length(uv-ball_position);

	float spots_clamp = 0.12;
	spots = clamp_dots(spots, spots_clamp, 1.0);
	float spot_seed = uv.x * uv.y * 9224.128456104 * t;
	color = color + (spots * 4.0 * fract(sin(spot_seed) * 234.948271)) - dark_spots * 0.8;

	// White core
	intensity = smoothstep(0.3, 0.01, outside_purple_distance);
	color += vec3(1.0, 1.0, 1.0) * 1.2 * intensity;

	// Final color
	color_out = vec4(color + lines, 1.0);
} 