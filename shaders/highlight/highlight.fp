#version 330

// Inputs
in vec2 var_texcoord0;

// Uniforms
uniform sampler2D texture_sampler;

// Custom uniforms for the highlight effect
uniform highlight_params
{
    vec4 highlight_color;     // RGB for glow color, A for glow intensity
    vec4 params;              // x: outline thickness, y: outer glow size, z: unused, w: unused
};

// Outputs
out vec4 color;

// Improved glow function with softer falloff
float glow_intensity(float distance, float max_distance, float intensity) {
    // Create a softer falloff curve that works with larger values
    return intensity * (1.0 - smoothstep(0.0, 1.0, distance / max_distance));
}

void main()
{
    // Sample the texture at the current position
    vec4 original = texture(texture_sampler, var_texcoord0);
    
    // Early return for fully transparent pixels to improve performance
    if (original.a < 0.01) {
        color = original;
        return;
    }
    
    // Configure parameters with better scaling for large values
    float thickness = params.x * 0.00001;    // Much smaller scale for very large values
    float glow_size = params.y * 0.00001;    // Much smaller scale for very large values
    
    // Initialize variables
    float glow_amount = 0.0;
    
    // Sample in a circular pattern around the current pixel
    const int SAMPLE_COUNT = 8;
    
    // The maximum distance to check for edges
    // This is directly controlled by the thickness parameter
    float max_check_distance = thickness;
    
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        float angle = float(i) * 6.28318 / float(SAMPLE_COUNT);
        vec2 direction = vec2(cos(angle), sin(angle));
        
        // Check along each ray for the edge
        for (float step = 1.0; step <= 4.0; step += 1.0) {
            // The distance scales with thickness
            float dist = step * max_check_distance / 4.0;
            vec2 sample_coord = var_texcoord0 + direction * dist;
            
            // Ensure we stay within texture bounds
            sample_coord = clamp(sample_coord, vec2(0.0), vec2(1.0));
            
            vec4 sample_color = texture(texture_sampler, sample_coord);
            
            // Edge detection - look for transition between transparent and opaque
            if (original.a < 0.5 && sample_color.a > 0.5) {
                // Calculate the glow with normalized distance values
                float intensity = glow_intensity(step/4.0, 1.0, 1.0);
                glow_amount = max(glow_amount, intensity);
            }
        }
    }
    
    // Apply the glow effect
    if (glow_amount > 0.01) {
        // Create glow color with enhanced brightness near edges
        vec3 glow_rgb = highlight_color.rgb * (1.0 + glow_amount * 0.7);
        
        // The glow alpha is affected by the highlight_color alpha and the calculated glow amount
        float glow_alpha = highlight_color.a * glow_amount;
        
        // Boost the alpha for better visibility
        glow_alpha = pow(glow_alpha, 0.75); // Make alpha falloff less steep
        
        vec4 glow_color = vec4(glow_rgb, glow_alpha);
        
        // Blend original with glow
        color = mix(original, glow_color, glow_color.a * (1.0 - original.a));
    } else {
        color = original;
    }
} 