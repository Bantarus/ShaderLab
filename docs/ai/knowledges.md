<think>
This is a great request. The user wants a comprehensive notes file that captures all the shader knowledge and techniques we're developing. This can serve as a reference for future work and improvements.

I'll create a detailed notes file that covers:
1. General shader principles in Defold
2. Specific implementation details for the dissolve and glitch effects
3. Techniques like IQ's palette
4. Optimization considerations
5. Troubleshooting common issues
6. Ideas for future enhancements

This should be structured in a way that makes it easy to add to over time.
</think>

# Defold Shader Development Notes

## Table of Contents
1. [Shader Fundamentals in Defold](#shader-fundamentals-in-defold)
2. [Dissolve Effect](#dissolve-effect)
3. [Glitch Effect](#glitch-effect)
4. [Color Palette Techniques](#color-palette-techniques)
5. [Optimization Tips](#optimization-tips)
6. [Common Issues & Solutions](#common-issues--solutions)
7. [Future Enhancement Ideas](#future-enhancement-ideas)
8. [Shader Conversion Guide](#shader-conversion-guide)
9. [Shader Utility Library](#shader-utility-library)

## Shader Fundamentals in Defold

### File Structure
- Each shader typically consists of:
  - `.vp` - Vertex program
  - `.fp` - Fragment program
  - `.material` - Material configuration
  - `.script` - Control script for animation/parameters

### Uniform Types
- **CONSTANT_TYPE_USER** - Custom values set from script
- **CONSTANT_TYPE_VIEWPROJ** - View projection matrix
- **CONSTANT_TYPE_WORLD** - World matrix
- **CONSTANT_TYPE_TEXTURE** - Texture sampler

### Key Components
```glsl
// Input from vertex shader
in vec2 var_texcoord0;

// Output to screen
out vec4 color_out;

// Sampler for textures
uniform sampler2D texture_sampler;

// Custom uniform block (required for SPIR-V compatibility)
uniform fs_uniforms {
    vec4 parameter1;  // x component is typically used
    vec4 parameter2;
};
```

### Scripting Integration
```lua
-- Set a shader parameter
go.set("#sprite", "parameter1", vmath.vector4(value, 0, 0, 0))

-- Animate a shader parameter
go.animate("#sprite", "parameter1.x", go.PLAYBACK_ONCE_FORWARD, 
           target_value, go.EASING_LINEAR, duration)
```

## Dissolve Effect

### Core Technique
- **Block-based digital dissolve** using a grid pattern
- Unique random dissolve threshold per block
- Edge highlighting with custom colors
- Time-based animation for dynamic effect

### Key Parameters
- **dissolve_amount**: Controls how much of the image is dissolved (0-1)
- **edge_width**: Width of the colored effect on dissolving edges
- **noise_scale**: Controls the block size (higher = smaller blocks)
- **time**: Animation controller for all dynamic effects

### Optimization Insights
- Early exit for non-dissolving state improves performance
- Using `floor()` for block creation is more efficient than `mod()`
- Separate alpha handling prevents edge artifacts

### Palette Integration
```glsl
// IQ's palette function produces smooth, vibrant colors
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);                  // offset
    vec3 b = vec3(palette_saturation.x);           // amplitude 
    vec3 c = vec3(1.0, 1.0, 1.0);                  // frequency
    vec3 d = vec3(0.0, 0.33, 0.67);                // phase
    
    // Generate the color using a cosine wave
    return a + b * cos(6.28318 * (c * t + d));
}
```

## Glitch Effect

### Core Techniques
- **RGB channel separation** (chromatic aberration)
- **Scan line jitter** (horizontal displacement)
- **Vertical shake** (whole image displacement)
- **Color drift** (shifting color balance)
- **Digital blocks** (corrupted rectangular regions)
- **Grayscale** effect for "power loss" appearance

### Key Parameters
- **glitch_intensity**: Master control for all effects (0-1)
- **rgb_shift**: Amount of RGB channel separation
- **scan_line_jitter**: Horizontal line displacement amount
- **vert_jitter**: Vertical shake amount
- **color_drift**: Color distortion amount
- **grayscale_amount**: Black and white effect amount (0-1)

### Optimization Insights
- Periodic effect updates (using `floor(time * freq)`) reduce visual noise
- Fixed scan line frequency prevents excessive jitter
- Separate grayscale path for when glitch intensity is 0
- Hash function provides deterministic randomness without textures

### Tuned Values
- Horizontal jump: amplitude 0.02, frequency 2.0
- Scan line frequency: 10.0
- Block corruption threshold: 0.96 (rare but noticeable)

## Color Palette Techniques

### Inigo Quilez's Palette Method
- Uses cosine waves to generate smooth color transitions
- Each parameter controls a different aspect of the palette:
  - **a**: Base color offset
  - **b**: Color amplitude (saturation)
  - **c**: Color cycle frequency
  - **d**: Phase shift (controls hue distribution)

### Preset Palettes
```glsl
// Cyberpunk
vec3 a = vec3(0.5, 0.5, 0.5); 
vec3 b = vec3(0.6);
vec3 c = vec3(1.0, 1.0, 1.0);
vec3 d = vec3(0.0, 0.33, 0.67);

// Vaporwave
vec3 a = vec3(0.5, 0.2, 0.5);
vec3 b = vec3(0.4);
vec3 c = vec3(1.0, 1.0, 1.0);
vec3 d = vec3(0.0, 0.1, 0.9);

// Fire
vec3 a = vec3(0.5, 0.0, 0.0);
vec3 b = vec3(0.5, 0.5, 0.2);
vec3 c = vec3(1.0, 1.0, 1.0);
vec3 d = vec3(0.0, 0.33, 0.67);

// Ice
vec3 a = vec3(0.1, 0.3, 0.5);
vec3 b = vec3(0.3);
vec3 c = vec3(1.0, 1.0, 1.0);
vec3 d = vec3(0.0, 0.1, 0.2);
```

## Optimization Tips

### Shader Performance
- Use `if (value < 0.001)` instead of `if (value == 0.0)` for floating point comparisons
- Early returns for non-effect states save processing time
- Minimize expensive operations like `sin()`, `cos()`, `pow()`
- Use `mix()` instead of manual lerp calculations
- Use `dot()` for grayscale conversion (perceptual weights: 0.299, 0.587, 0.114)

### Animation Performance
- Control animation speed through scripts rather than shader recompilation
- Use time scaling for slower/faster effects: `time.x * speed_factor`
- Batch uniform updates when possible
- Cache calculated values in local variables

## Common Issues & Solutions

### Uneven Dissolve Effect
- **Issue**: Some blocks visible when dissolve_amount = 0
- **Solution**: Ensure threshold calculation produces values ≥ 0 when not dissolving

### Erratic Glitch Animation
- **Issue**: Glitch effects change too rapidly/randomly
- **Solution**: Use time quantization (`floor(time * freq)`) to make effects persist longer

### Color Banding
- **Issue**: Visible steps in color gradients
- **Solution**: Add subtle noise to color transitions or use higher precision

### Performance Drops
- **Issue**: FPS drops with complex shaders
- **Solution**: 
  - Use early returns when effects are minimal
  - Reduce texture lookups
  - Decrease effect resolution for less important elements

## Future Enhancement Ideas

### Dissolve Effect Enhancements
- Directional dissolve (left-to-right, center-out)
- Texture-driven dissolve patterns
- Particle emission from dissolve edges
- Sound synchronization

### Glitch Effect Enhancements
- Data corruption patterns that look like ASCII/text
- Fake screen tearing
- Bloom/glow on corrupted areas
- CRT curvature and scan lines
- Random image displacement (datamosh effect)

### New Effect Ideas
- Hologram effect with scan lines and flickering
- Pixelation transitions
- Heat distortion
- Water/ripple effects
- Electric/lightning effects

## Shader Conversion Guide

### Converting ShaderToy/GLSL Shaders to Defold

#### Step 1: Understand the Original Shader Structure
- **ShaderToy** shaders typically have:
  - `mainImage(out vec4 fragColor, in vec2 fragCoord)` as the main function
  - `iResolution`, `iTime`, `iMouse` as standard uniforms
  - No vertex shader component

- **Generic GLSL** shaders might have:
  - `main()` function with `gl_FragColor` output
  - Various uniform declarations
  - Potentially multiple shader stages (vertex, geometry, etc.)

#### Step 2: Create Defold Shader Files

1. **Create the Vertex Program (.vp)**
   ```glsl
   #version 330

   // Input attributes
   in vec4 position;
   in vec2 texcoord0;

   // Uniforms block
   uniform shader_name_vp {
       mat4 view_proj;
   };

   // Output to fragment shader
   out vec2 var_texcoord0;
   out vec2 var_frag_coord;

   void main()
   {
       gl_Position = view_proj * vec4(position.xyz, 1.0);
       var_texcoord0 = texcoord0;
       var_frag_coord = texcoord0;
   }
   ```

2. **Create the Fragment Program (.fp)**
   ```glsl
   #version 330

   // Input from vertex shader
   in vec2 var_texcoord0;
   in vec2 var_frag_coord;

   // Output
   out vec4 color_out;

   // Uniforms block
   uniform shader_name_fp {
       vec4 resolution;  // Screen resolution (x,y) components
       vec4 time;        // Current time in seconds (x component)
       // Other custom parameters
   };

   // Textures
   uniform sampler2D texture_sampler;

   void main() {
       // Your shader code goes here
       // ...
       
       color_out = vec4(1.0); // Replace with actual output
   }
   ```

3. **Create Material File (.material)**
   ```
   name: "shader_name"
   tags: "tile"
   vertex_program: "/path/to/shader_name.vp"
   fragment_program: "/path/to/shader_name.fp"
   vertex_constants {
     name: "view_proj"
     type: CONSTANT_TYPE_VIEWPROJ
   }
   fragment_constants {
     name: "resolution"
     type: CONSTANT_TYPE_USER
     value {
       x: 1280.0
       y: 720.0
     }
   }
   fragment_constants {
     name: "time"
     type: CONSTANT_TYPE_USER
     value {
     }
   }
   samplers {
     name: "texture_sampler"
     wrap_u: WRAP_MODE_REPEAT
     wrap_v: WRAP_MODE_REPEAT
     filter_min: FILTER_MODE_MIN_LINEAR
     filter_mag: FILTER_MODE_MAG_LINEAR
   }
   ```

#### Step 3: Adapt ShaderToy-Specific Code

| ShaderToy              | Defold Equivalent                           |
|------------------------|---------------------------------------------|
| `fragCoord`            | `var_frag_coord * resolution.xy`            |
| `iResolution.xy`       | `resolution.xy`                             |
| `iTime`                | `time.x`                                    |
| `fragColor = vec4(...)`| `color_out = vec4(...)`                     |
| `texture(iChannel0, ...)` | `texture(texture_sampler, ...)`          |

#### Step 4: SPIR-V Compatibility Adjustments

1. **Use Uniform Blocks**
   - All non-opaque uniforms (like floats, vectors, matrices) must be in uniform blocks
   ```glsl
   // Instead of this:
   uniform vec4 resolution;
   
   // Do this:
   uniform shader_name_fp {
       vec4 resolution;
   };
   ```

2. **Use `in`/`out` Instead of `varying`**
   - Modern GLSL uses `in` and `out` qualifiers instead of `varying`

3. **Define Output Variables**
   - Instead of using `gl_FragColor`, define an output variable:
   ```glsl
   out vec4 color_out;
   ```

4. **OpenGL 3.3+ Features**
   - Use version directive `#version 330` or higher
   - Use appropriate texture functions (e.g., `texture` instead of `texture2D`)

#### Step 5: Handle Coordinate Systems

1. **Normalized vs. Pixel Coordinates**
   - ShaderToy uses pixel coordinates (0 to resolution)
   - Defold uses normalized coordinates (0 to 1)
   - Convert between them as needed:
   ```glsl
   // Convert normalized to pixel coordinates
   vec2 pixelCoord = var_frag_coord * resolution.xy;
   
   // Convert pixel to normalized
   vec2 normalizedCoord = fragCoord / resolution.xy;
   ```

2. **Center-Based Coordinates**
   - For effects that work from the center, convert to (-1 to 1) range:
   ```glsl
   vec2 centered = var_frag_coord * 2.0 - 1.0;
   ```

3. **Aspect Ratio Correction**
   - For circular/spherical effects:
   ```glsl
   float aspect = resolution.x / resolution.y;
   if (aspect > 1.0) {
       uv.x *= aspect;
   } else {
       uv.y /= aspect;
   }
   ```

#### Step 6: Create Control Script

```lua
function init(self)
    -- Initialize time
    self.time = 0
    
    -- Set resolution
    local width, height = window.get_size()
    go.set("#sprite", "resolution", vmath.vector4(width, height, 0, 0))
end

function update(self, dt)
    -- Update time
    self.time = self.time + dt
    go.set("#sprite", "time.x", self.time)
end

function on_message(self, message_id, message, sender)
    -- Handle window resizing
    if message_id == hash("window_resized") then
        local width = message.width
        local height = message.height
        go.set("#sprite", "resolution", vmath.vector4(width, height, 0, 0))
    end
end
```

### Real-World Example: Energy Ball Shader Conversion

1. **Original ShaderToy Code**
   - Main function with fragCoord and iResolution
   - Uses pixel-based coordinates and iTime
   - Complex effect with multiple components

2. **Defold Implementation**
   - Separated vertex and fragment programs
   - Added uniform blocks for SPIR-V compatibility
   - Adjusted coordinate systems for Defold
   - Structured parameters into logical groups
   - Added a control script for time and resolution updates

3. **Solved Issues During Conversion**
   - Fixed aspect ratio handling for circular shapes
   - Ensured proper texture coordinate handling
   - Optimized loops for mobile performance
   - Added safety checks for shader variables

4. **Tips for Future Conversions**
   - Start with a minimal working version, then add complexity
   - Test frequently as you convert each component
   - Use a utility file for common functions
   - Keep parameter organization consistent across shaders
   - Document all uniform parameters for easier scripting

## Shader Utility Library

### Overview
Our shader utility library (`shader_lib.glsl`) provides reusable functions for common shader operations. This reduces code duplication and promotes consistency across all shaders.

### Including the Library in Shaders
To use the utility library in your Defold shaders:

```glsl
// At the top of your .fp or .vp file
#include "/shaders/util/shader_lib.glsl"

// Now you can use any function from the library
void main() {
    // Example: Using the palette function
    vec3 color = palette_cyberpunk(time.x * 0.2);
    
    // Example: Using aspect ratio correction
    vec2 uv = var_frag_coord;
    uv = normalizedToCenter(uv);
    uv = aspectCorrect(uv, resolution.x/resolution.y);
    
    // Example: Adding a vignette effect
    float vig = vignette(var_frag_coord, 1.2, 0.8);
    color *= vig;
}
```

### Key Function Categories

#### Color Functions
- `palette(t, a, b, c, d)` - IQ's color palette formula
- `palette_cyberpunk(t)`, `palette_fire(t)`, etc. - Pre-defined color palettes
- `rgb2gray(color)` - Convert RGB to grayscale using perceptual weights

#### Drawing Utilities
- `drawLine(start, end, uv, thickness)` - Draw a line with uniform thickness
- `drawCircle(center, radius, uv)` - Draw a filled circle
- `drawCircleOutline(center, radius, thickness, uv)` - Draw a circle outline

#### Noise and Random
- `hash(float)`, `hash(vec2)` - Hash functions for pseudo-random numbers
- `noise(p)` - 2D value noise function
- `fbm(p, octaves, lacunarity, gain)` - Fractal Brownian Motion noise

#### Effects
- `chromaticAberration(tex, uv, strength)` - RGB channel separation
- `vignette(uv, strength, smoothness)` - Screen edge darkening
- `normalMap(tex, uv, time, strength)` - Generate normals from height maps

#### Distortion
- `radialDistortion(uv, strength)` - Barrel/pincushion distortion
- `waterRipple(uv, time, strength, frequency)` - Animated ripple effect

#### Coordinate Utilities
- `normalizedCoords(pixelCoord, resolution)` - Convert pixel to 0-1 range
- `normalizedToCenter(uv)` - Convert 0-1 to -1 to 1 range
- `aspectCorrect(uv, aspectRatio)` - Fix aspect ratio for circles/squares

#### Animation
- `easeOutBounce(t)`, `easeOutElastic(t)` - Animation easing functions
- `pulse(t, width)` - Smooth pulsing effect

#### Lighting
- `diffuse(normal, lightDir)` - Basic diffuse lighting calculation
- `specular(normal, lightDir, viewDir, shininess)` - Phong specular reflection
- `fresnel(normal, viewDir, power)` - Fresnel edge effect

### Benefits of Using the Library
1. **Code Reuse** - Avoid duplicating common functions across shaders
2. **Consistency** - All shaders use the same implementation of core functions
3. **Maintenance** - Fix bugs or improve functions in one place
4. **Readability** - Cleaner shader code with well-named utility functions
5. **Efficiency** - Tested and optimized implementations

### Example: Before and After

Without the library:
```glsl
// Lots of utility code at the top of each shader
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) { /* lengthy implementation */ }
vec3 palette(float t) { /* palette code */ }
// ... many more utility functions

void main() {
    // Actual shader logic
}
```

With the library:
```glsl
#include "/shaders/util/shader_lib.glsl"

void main() {
    // Focus directly on the shader-specific logic
    // Use library functions as needed
}
```

### Extending the Library
When you develop a new utility function that might be useful in other shaders:
1. Test it thoroughly in your current shader
2. Move it to the appropriate section in `shader_lib.glsl`
3. Document its parameters and usage
4. Update your shader to use the library version

This practice will gradually build a comprehensive toolkit for all your shader development needs.

---

*This document will be updated as we continue to refine and develop shader effects.*
