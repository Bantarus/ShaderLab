#version 330

// Inputs from vertex shader
in vec2 var_texcoord0;

// Output
out vec4 color_out;

// Opaque uniforms don't need blocks
uniform sampler2D texture_sampler;

// Non-opaque uniforms in a block for SPIR-V compatibility
uniform fs_uniforms
{
	vec4 vortex_color;
	vec4 glow_color;
	vec4 touch_position;
	vec4 time;
	vec4 vortex_strength;
	vec4 vortex_radius;
	vec4 dissolve_amount;
};

void main()
{
	// Calculate distance from current fragment to touch position
	vec2 touch_pos_normalized = touch_position.xy;
	vec2 frag_pos = var_texcoord0;
	float distance_to_touch = length(frag_pos - touch_pos_normalized);

	// Original texture color
	vec4 original_color = texture(texture_sampler, var_texcoord0);

	// Vortex effect
	float vortex_angle = atan(frag_pos.y - touch_pos_normalized.y, frag_pos.x - touch_pos_normalized.x);
	float swirl = vortex_strength.x * sin(distance_to_touch * 10.0 - time.x * 3.0);
	vec2 swirl_offset = vec2(
		cos(vortex_angle + swirl) * distance_to_touch,
		sin(vortex_angle + swirl) * distance_to_touch
	) * 0.1;

	// Sample with swirl offset for the card texture
	vec2 swirled_coords = var_texcoord0 + swirl_offset * dissolve_amount.x;
	vec4 swirled_color = texture(texture_sampler, swirled_coords);

	// Energy ball/vortex effect
	float energy_intensity = smoothstep(vortex_radius.x, 0.0, distance_to_touch);
	float pulse = 0.5 + 0.5 * sin(time.x * 4.0);
	float energy_ring = smoothstep(0.0, 0.1, abs(distance_to_touch - vortex_radius.x * 0.6 * (0.8 + 0.2 * pulse)));

	// Spinning effect inside the energy ball
	float spin_angle = vortex_angle + time.x * 3.0;
	float spin_pattern = 0.5 + 0.5 * sin(spin_angle * 6.0);

	// Mix colors based on distance and dissolve amount
	vec4 energy_color = mix(glow_color, vortex_color, spin_pattern);

	// Final color
	vec4 final_color;

	// Card to vortex transition based on dissolve amount
	if (distance_to_touch < vortex_radius.x) {
		// Inside vortex radius
		float vortex_visibility = energy_intensity * (1.0 - energy_ring * 0.8);
		final_color = mix(swirled_color, energy_color, vortex_visibility * dissolve_amount.x);
	} else {
		// Outside vortex radius - transition based on dissolve amount
		final_color = mix(original_color, swirled_color, dissolve_amount.x);
	}

	// Apply alpha from original texture
	final_color.a = original_color.a;

	// Set the output color (instead of using gl_FragColor)
	color_out = final_color;
}