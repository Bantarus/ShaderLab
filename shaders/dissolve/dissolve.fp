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
    vec4 dissolve_amount;  // x: amount of dissolve (0-1)
    vec4 edge_color;       // Edge glow color
    vec4 edge_width;       // x: width of the edge effect (0-0.5 recommended)
    vec4 noise_scale;      // x: scale of noise pattern (controls block size)
    vec4 time;             // x: time for animated effect
    vec4 palette_speed;    // x: speed of color palette cycling
    vec4 palette_offset;   // x: offset into color palette
    vec4 palette_saturation; // x: color saturation (0-1)
};

// IQ's palette function from https://iquilezles.org/articles/palettes/
vec3 palette(float t) {
    // Define the palette parameters

   
    vec3 c = vec3(1.0, 1.0, 1.0);  
    vec3 a = vec3(0.1, 0.3, 0.5); vec3 b = vec3(0.3); vec3 d = vec3(0.0, 0.1, 0.2);
    // Generate the color using a cosine wave
    return a + b * cos(6.28318 * (c * t + d));
}

void main()
{
    // Sample the main texture
    vec4 sprite_color = texture(texture_sampler, var_texcoord0);
    
    // If fully transparent in the original texture, discard immediately
    if (sprite_color.a < 0.01) {
        discard;
    }
    
    // If dissolve amount is 0, just show the original image with no effects
    if (dissolve_amount.x <= 0.001) {
        color_out = sprite_color;
        return;
    }
    
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
        
        // Generate a color for this block using IQ's palette technique
        // Use a combination of block position, time, and block_seed for variety
        float palette_t = block_seed;
        
        // Add time component for animated colors
        palette_t += time.x * palette_speed.x;
        
        // Add palette offset
        palette_t += palette_offset.x;
        
        // Get the color from our palette function
        vec3 block_color = palette(palette_t);
        
        // Create digital effect - blocks near the threshold get their own color
        // Mix with original color based on proximity to edge
        sprite_color.rgb = mix(sprite_color.rgb, block_color, intensity);
        
        // Add inner edge highlight 
        if (edge_in_block < 0.15) {
            float edge_intensity = (0.15 - edge_in_block) / 0.15;
            sprite_color.rgb = mix(sprite_color.rgb, edge_color.rgb, edge_intensity * 0.7);
        }
    }
    
    // Output the final color
    color_out = sprite_color;
} 