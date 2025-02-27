#version 330

// Inputs must match vertex shader outputs
in vec2 var_texcoord0;
in vec4 var_color;

// Single output for final color
out vec4 color;

// Texture sampler (opaque uniform, no block needed)
uniform sampler2D texture_sampler;

// Non-opaque uniforms must be in uniform blocks for SPIR-V
uniform outline_fp {
	vec4 texture_size_px;           // Width and height of the texture
	vec4 inner_outline_color;       // RGBA color for outline
	vec4 inner_outline_settings;    // x: enable (0=off, 1=on), y: width, z: fade
	vec4 distortion_settings;       // x: toggle (0=off, 1=on), y, z: intensity, w: unused
	vec4 noise_settings;            // x, y: scale, z, w: speed
	vec4 time;                      // x: time for animation
	vec4 texture_settings;          // x: toggle (0=off, 1=on), y, z: speed, w: outline-only mode
};

// Second texture sampler for tint effect
uniform sampler2D outline_texture;

// Noise function (simplified perlin-like noise)
float noise(vec2 p) {
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(fract(sin(dot(ip, vec2(12.9898, 78.233))) * 43758.5453), 
			fract(sin(dot(ip + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453), u.x),
		mix(fract(sin(dot(ip + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453), 
			fract(sin(dot(ip + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453), u.x), u.y);
	return res * res;
}

void main()
{
	// Default color from texture
	vec4 tex_color = texture(texture_sampler, var_texcoord0) * var_color;
	
	// Early return if inner outline is disabled
	if (inner_outline_settings.x < 0.5) {
		color = tex_color;
		return;
	}
	
	// Initialize variables for the inner outline effect
	vec2 pixel_size = 1.0 / texture_size_px.xy;
	float width_scale = inner_outline_settings.y * 100.0;
	vec2 uv = var_texcoord0;
	
	// Apply distortion if enabled
	if (distortion_settings.x > 0.5) {
		float noise_value = noise((uv + noise_settings.zw * time.x) * noise_settings.xy) - 0.5;
		uv += distortion_settings.yz * noise_value;
	}
	
	// Get color for the inner outline
	vec4 outline_color_final = inner_outline_color;
	
	// Apply texture tint if enabled
	if (texture_settings.x > 0.5) {
		vec2 tint_uv = uv + texture_settings.yz * time.x;
		vec4 tint_color = texture(outline_texture, tint_uv);
		outline_color_final = outline_color_final * tint_color;
	}
	
	// Sample the texture at 8 surrounding positions
	float alpha1 = texture(texture_sampler, uv + vec2(0, -pixel_size.y) * width_scale).a;
	float alpha2 = texture(texture_sampler, uv + vec2(0, pixel_size.y) * width_scale).a;
	float alpha3 = texture(texture_sampler, uv + vec2(-pixel_size.x, 0) * width_scale).a;
	float alpha4 = texture(texture_sampler, uv + vec2(pixel_size.x, 0) * width_scale).a;
	float alpha5 = texture(texture_sampler, uv + vec2(0.705 * pixel_size.x, 0.705 * pixel_size.y) * width_scale).a;
	float alpha6 = texture(texture_sampler, uv + vec2(-0.705 * pixel_size.x, 0.705 * pixel_size.y) * width_scale).a;
	float alpha7 = texture(texture_sampler, uv + vec2(0.705 * pixel_size.x, -0.705 * pixel_size.y) * width_scale).a;
	float alpha8 = texture(texture_sampler, uv + vec2(-0.705 * pixel_size.x, -0.705 * pixel_size.y) * width_scale).a;
	
	// Calculate the minimum alpha from all samples
	float min_alpha = min(min(min(min(min(min(min(alpha1, alpha2), alpha3), alpha4), alpha5), alpha6), alpha7), alpha8);
	
	// Calculate the inner outline effect strength
	float outline_strength = (1.0 - min_alpha) * inner_outline_settings.z;
	
	// Apply the outline effect
	if (texture_settings.w > 0.5) {
		// Outline only mode - only show the outline based on the texture's alpha
		color = vec4(outline_color_final.rgb, outline_strength * tex_color.a);
	} else {
		// Normal mode - blend the outline with the original texture
		vec3 result_color = mix(tex_color.rgb, outline_color_final.rgb, outline_strength);
		color = vec4(result_color, tex_color.a);
	}
}