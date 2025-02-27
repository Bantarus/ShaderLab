#version 330

// Inputs from vertex shader
in vec2 var_texcoord0;

// Output
out vec4 color_out;

// Opaque uniforms (don't need blocks)
uniform sampler2D texture_sampler;  // Main sprite texture

// Non-opaque uniforms in a block for SPIR-V compatibility
uniform fs_uniforms
{
    // Dissolve uniforms
    vec4 dissolve_amount;  // x: amount of dissolve (0-1)
    vec4 edge_color;       // Edge glow color
    vec4 edge_width;       // x: width of the edge effect (0-0.5 recommended)
    vec4 noise_scale;      // x: scale of noise pattern (controls block size)
    
    // Glitch uniforms
    vec4 glitch_intensity; // x: overall intensity of glitch effect (0-1)
    vec4 rgb_shift;        // x: amount of RGB shifting
    vec4 scan_line_jitter; // x: scan line jitter amount
    vec4 vert_jitter;      // x: vertical jitter amount
    vec4 color_drift;      // x: color drift amount
    vec4 grayscale_amount; // x: amount of grayscale effect (0-1)
    
    // Shared uniform
    vec4 time;             // x: time for animated effects
};

// Hash function for pseudo-random numbers
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Function to generate vibrant colors based on position
vec3 generate_color(vec2 block_pos) {
    // Generate a pseudo-random but deterministic value for this block
    float seed = fract(sin(dot(block_pos, vec2(12.9898, 78.233))) * 43758.5453);
    
    // Generate a vibrant color palette
    // Method 1: HSV-inspired color generation (simplified)
    float hue = fract(seed * 3.7 + time.x * 0.1) * 6.28318;
    vec3 color = vec3(
        0.8 + 0.2 * sin(hue),
        0.8 + 0.2 * sin(hue + 4.1888), // 4π/3
        0.8 + 0.2 * sin(hue + 2.0944)  // 2π/3
    );
    
    // Enhance color contrast
    color = clamp(color * 1.5 - 0.25, 0.0, 1.0);
    
    return color;
}

void main()
{
    // Sample the main texture
    vec4 sprite_color = texture(texture_sampler, var_texcoord0);
    
    // If fully transparent in the original texture, discard immediately
    if (sprite_color.a < 0.01) {
        discard;
    }
    
    // =====================
    // APPLY GLITCH EFFECT
    // =====================
    
    // Only apply glitch effect if intensity > 0
    if (glitch_intensity.x > 0.001) {
        float time_val = time.x;
        vec2 uv = var_texcoord0;
        
        // Apply glitch intensity to all effects
        float intensity = glitch_intensity.x;
        
        // Generate noise values for various effects
        float noise1 = hash(floor(time_val * 10.0) + 1.0);
        float noise2 = hash(floor(time_val * 10.0) + 2.0);
        float noise3 = hash(floor(time_val * 10.0) + 3.0);
        
        // Scan line jitter - horizontal displacement with scan line pattern
        float scan_line_jitter_amount = scan_line_jitter.x * intensity;
        // Lower multiplier = less frequent scan lines
        float scan_line_freq = 10.0; 
        float y_jitter_influence = abs(sin(uv.y * scan_line_freq + time_val * 5.0));
        float x_offset = scan_line_jitter_amount * noise1 * y_jitter_influence;
        
        // Vertical shake - whole image vertical displacement
        float vert_jitter_amount = vert_jitter.x * intensity;
        float y_offset = vert_jitter_amount * noise2;
        
        // Occasional horizontal jump (occurs in "blocks")
        float block_factor = floor(uv.y * 15.0);
        // Only change jump chance periodically (every few seconds)
        float jump_time = floor(time_val * 0.2); 
        float jump_chance = hash(block_factor + jump_time);

        // Apply horizontal jump occasionally
        if (jump_chance > 0.75) {
            x_offset += 0.02 * intensity * sin(time_val * 2.0 + block_factor);
        }
        
        // RGB shift (color channel separation)
        float rgb_amount = rgb_shift.x * intensity;
        
        // Sample with various distortions
        vec2 distort_uv = vec2(uv.x + x_offset, uv.y + y_offset);
        
        // Sample red channel with offset
        float r = texture(texture_sampler, distort_uv + vec2(rgb_amount * noise3, 0.0)).r;
        
        // Sample green channel with smaller offset
        float g = texture(texture_sampler, distort_uv + vec2(-rgb_amount * noise3 * 0.5, 0.0)).g;
        
        // Sample blue channel with different offset
        float b = texture(texture_sampler, distort_uv + vec2(0.0, rgb_amount * noise1 * 0.5)).b;
        
        // Sample alpha from main position to prevent edge artifacts
        float a = texture(texture_sampler, distort_uv).a;
        
        // Digital blocks effect - create rectangular corrupted regions
        // Only change block corruptions periodically
        float block_time = floor(time_val * 0.3);
        if (hash(block_factor * 3.14 + block_time) > 0.96) {
            // Create a corrupted block
            float block_width = hash(block_factor) * 0.1 + 0.02;
            float block_x = hash(floor(time_val * 3.0) + block_factor);
            
            if (uv.x > block_x && uv.x < block_x + block_width) {
                // Corrupt this region with wrong color data
                r = hash(block_factor + 1.0);
                g = hash(block_factor + 2.0);
                b = hash(block_factor + 3.0);
            }
        }
        
        // Color drift effect - shift color balance
        float color_drift_amount = color_drift.x * intensity;
        float drift_r = sin(time_val * 2.0) * color_drift_amount;
        float drift_g = sin(time_val * 3.0) * color_drift_amount;
        float drift_b = sin(time_val * 4.0) * color_drift_amount;
        
        // Apply color drift
        r += drift_r;
        g += drift_g;
        b += drift_b;
        
        // Add scan lines
        float scan_line = sin(uv.y * 400.0) * 0.08 * intensity;
        r -= scan_line;
        g -= scan_line;
        b -= scan_line;
        
        // Add pixelation to some areas
        float pixelation_chance = hash(floor(time_val * 5.0) + floor(uv.y * 10.0));
        if (pixelation_chance > 0.95) {
            float pixel_size = 0.02 * intensity;
            vec2 pixelated_uv = floor(uv / pixel_size) * pixel_size;
            vec4 pixelated_color = texture(texture_sampler, pixelated_uv);
            
            // Mix with the glitched colors
            float mix_amount = 0.5;
            r = mix(r, pixelated_color.r, mix_amount);
            g = mix(g, pixelated_color.g, mix_amount);
            b = mix(b, pixelated_color.b, mix_amount);
        }
        
        // Create glitched color
        vec3 glitched_color = vec3(r, g, b);
        
        // Apply grayscale if needed
        if (grayscale_amount.x > 0.001) {
            // Standard grayscale conversion using luminance weights
            float gray = dot(glitched_color, vec3(0.299, 0.587, 0.114));
            
            // Mix between color and grayscale based on amount
            glitched_color = mix(glitched_color, vec3(gray), grayscale_amount.x);
        }
        
        // Update sprite color with glitched color
        sprite_color = vec4(glitched_color, a);
    }
    
    // =====================
    // APPLY DISSOLVE EFFECT
    // =====================
    
    // Only apply dissolve effect if dissolve amount > 0
    if (dissolve_amount.x > 0.001) {
        // Create blocky grid pattern by flooring the coordinates
        // The block size is controlled by noise_scale.x (larger value = smaller blocks)
        float block_size = 1.0 / noise_scale.x;
        vec2 block_coord = floor(var_texcoord0 / block_size) * block_size;
        vec2 block_id = floor(var_texcoord0 / block_size); // For color generation
        
        // Calculate position within block (0-1) for edge effects
        vec2 pos_in_block = fract(var_texcoord0 / block_size);
        float edge_in_block = min(
            min(pos_in_block.x, 1.0 - pos_in_block.x),
            min(pos_in_block.y, 1.0 - pos_in_block.y)
        );
        
        // Generate a unique but deterministic dissolve threshold for each block
        // This will make blocks appear/disappear in a semi-random order
        float block_seed = fract(sin(dot(block_id, vec2(12.9898, 78.233))) * 43758.5453);
        
        // Add time component for animated digitalization effect
        // Different blocks will appear/disappear at different times
        float time_offset = (sin(time.x * 2.0 + block_seed * 6.28318) * 0.5 + 0.5) * 0.1;
        float block_threshold = block_seed + time_offset;
        
        // Compare with dissolve amount to determine if this block should be visible
        if (block_threshold < dissolve_amount.x) {
            discard; // This block is dissolved
        }
        
        // For blocks near the dissolve threshold, apply special effects
        float dissolve_proximity = block_threshold - dissolve_amount.x;
        
        if (dissolve_proximity < edge_width.x) {
            // Blocks that are about to appear/disappear
            float intensity = 1.0 - dissolve_proximity / edge_width.x;
            
            // Generate a color for this block
            vec3 block_color = generate_color(block_id);
            
            // Create digital effect - blocks near the threshold get their own color
            // Mix with original color based on proximity to edge
            sprite_color.rgb = mix(sprite_color.rgb, block_color, intensity);
            
            // Add inner edge highlight 
            if (edge_in_block < 0.15) {
                float edge_intensity = (0.15 - edge_in_block) / 0.15;
                sprite_color.rgb = mix(sprite_color.rgb, edge_color.rgb, edge_intensity * 0.7);
            }
        }
    }
    
    // Output the final color
    color_out = sprite_color;
} 