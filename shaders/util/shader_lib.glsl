// =============================================================================
// Defold Shader Utility Library
// =============================================================================

// -----------------------------------------------------------------------------
// Color Palettes (based on Inigo Quilez's techniques)
// -----------------------------------------------------------------------------

// IQ's color palette function
// Creates a smooth color palette based on cosine waves
// t: value between 0.0 and 1.0 (position in the palette)
// a: base color (offset)
// b: color amplitude (affects saturation)
// c: color frequency
// d: phase values (controls hue distribution)
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

// Pre-defined palettes

// Cyberpunk palette - purples, blues and pinks
vec3 palette_cyberpunk(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);
    return palette(t, a, b, c, d);
}

// Fire palette - warm oranges, reds and yellows
vec3 palette_fire(float t) {
    vec3 a = vec3(0.5, 0.2, 0.0);
    vec3 b = vec3(0.5, 0.4, 0.2);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.15, 0.2);
    return palette(t, a, b, c, d);
}

// Electric palette - bright blues and cyans
vec3 palette_electric(float t) {
    vec3 a = vec3(0.2, 0.4, 0.6);
    vec3 b = vec3(0.3, 0.6, 0.8);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.8, 0.9, 0.3);
    return palette(t, a, b, c, d);
}

// Rainbow palette - full spectrum
vec3 palette_rainbow(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);
    return palette(t, a, b, c, d);
}

// Grayscale palette
vec3 palette_grayscale(float t) {
    return vec3(t);
}

// -----------------------------------------------------------------------------
// Noise and Random Functions
// -----------------------------------------------------------------------------

// Hash function for pseudo-random numbers
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D noise function (value noise)
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Four corners in 2D of a tile
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// Fractal Brownian Motion (fBm)
float fbm(vec2 p, int octaves, float lacunarity, float gain) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= gain;
        frequency *= lacunarity;
    }
    
    return value;
}

// -----------------------------------------------------------------------------
// Utility Shapes and Drawing
// -----------------------------------------------------------------------------

// Draw a line between two points with variable thickness
float drawLine(vec2 start, vec2 end, vec2 uv, float thickness) {
    vec2 dir = normalize(end - start);
    vec2 uv_to_start = uv - start;
    float projection = clamp(dot(uv_to_start, dir), 0.0, length(end - start));
    vec2 closest_point = start + projection * dir;
    float dist = length(uv - closest_point);
    return smoothstep(thickness, thickness - 0.005, dist);
}

// Draw a line with varying thickness from start to end
float drawLineVaryingThickness(vec2 start, vec2 end, vec2 uv, float thickness_start, float thickness_end) {
    vec2 dir = normalize(end - start);
    vec2 uv_to_start = uv - start;
    float projection = clamp(dot(uv_to_start, dir), 0.0, length(end - start));
    vec2 closest_point = start + projection * dir;
    float dist = length(uv - closest_point);
    
    // Interpolate thickness based on position along line
    float t = projection / length(end - start);
    float thickness = mix(thickness_start, thickness_end, t);
    
    return smoothstep(thickness, thickness - 0.005, dist);
}

// Draw a circle
float drawCircle(vec2 center, float radius, vec2 uv) {
    float dist = length(uv - center);
    return smoothstep(radius, radius - 0.005, dist);
}

// Draw a circle outline
float drawCircleOutline(vec2 center, float radius, float thickness, vec2 uv) {
    float dist = length(uv - center);
    float outer = smoothstep(radius, radius - 0.005, dist);
    float inner = smoothstep(radius - thickness, radius - thickness - 0.005, dist);
    return outer - inner;
}

// -----------------------------------------------------------------------------
// Effects and Transformations
// -----------------------------------------------------------------------------

// RGB to grayscale conversion (using perceptual weights)
float rgb2gray(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

// Chromatic aberration effect
vec3 chromaticAberration(sampler2D tex, vec2 uv, float strength) {
    float r = texture(tex, uv - vec2(strength, 0.0)).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv + vec2(strength, 0.0)).b;
    return vec3(r, g, b);
}

// Vignette effect
float vignette(vec2 uv, float strength, float smoothness) {
    uv = (uv - 0.5) * 2.0; // remap to -1 to 1
    float vignette = 1.0 - dot(uv, uv) * strength;
    return smoothstep(0.0, smoothness, vignette);
}

// Screen-space normal mapping
vec3 normalMap(sampler2D tex, vec2 uv, float time, float strength) {
    float step = 0.01;
    float height_c = texture(tex, uv).r;
    float height_r = texture(tex, uv + vec2(step, 0.0)).r;
    float height_u = texture(tex, uv + vec2(0.0, step)).r;
    
    vec3 normal = normalize(vec3(
        (height_c - height_r) * strength,
        (height_c - height_u) * strength,
        1.0
    ));
    
    return normal;
}

// -----------------------------------------------------------------------------
// Distortion Effects
// -----------------------------------------------------------------------------

// Radial distortion
vec2 radialDistortion(vec2 uv, float strength) {
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;
    float dist = length(offset);
    float distortion = 1.0 + strength * dist * dist;
    return center + offset * distortion;
}

// Water ripple effect
vec2 waterRipple(vec2 uv, float time, float strength, float frequency) {
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;
    float dist = length(offset);
    float angle = atan(offset.y, offset.x);
    
    float wave = sin(dist * frequency - time) * strength;
    float x = cos(angle) * (dist + wave);
    float y = sin(angle) * (dist + wave);
    
    return center + vec2(x, y);
}

// -----------------------------------------------------------------------------
// Texture Utilities
// -----------------------------------------------------------------------------

// Normalized texture coordinates from pixel coordinates
vec2 normalizedCoords(vec2 pixelCoord, vec2 resolution) {
    return pixelCoord / resolution;
}

// Convert normalized coords to -1 to 1 range (centered at origin)
vec2 normalizedToCenter(vec2 uv) {
    return (uv - 0.5) * 2.0;
}

// Apply aspect ratio correction to maintain proper circles/squares
vec2 aspectCorrect(vec2 uv, float aspectRatio) {
    if (aspectRatio > 1.0) {
        // Landscape
        uv.x *= aspectRatio;
    } else {
        // Portrait
        uv.y /= aspectRatio;
    }
    return uv;
}

// -----------------------------------------------------------------------------
// Animation Utilities
// -----------------------------------------------------------------------------

// Bounce easing function
float easeOutBounce(float t) {
    float n1 = 7.5625;
    float d1 = 2.75;
    
    if (t < 1.0 / d1) {
        return n1 * t * t;
    } else if (t < 2.0 / d1) {
        t -= 1.5 / d1;
        return n1 * t * t + 0.75;
    } else if (t < 2.5 / d1) {
        t -= 2.25 / d1;
        return n1 * t * t + 0.9375;
    } else {
        t -= 2.625 / d1;
        return n1 * t * t + 0.984375;
    }
}

// Elastic easing function
float easeOutElastic(float t) {
    float p = 0.3;
    return pow(2.0, -10.0 * t) * sin((t - p / 4.0) * (2.0 * 3.14159) / p) + 1.0;
}

// Smooth pulse function (0 to 1 to 0)
float pulse(float t, float width) {
    t = mod(t, 1.0);
    return smoothstep(0.0, width, t) * smoothstep(1.0, width, 1.0 - t);
}

// -----------------------------------------------------------------------------
// Lighting and Shading
// -----------------------------------------------------------------------------

// Simple diffuse lighting
float diffuse(vec3 normal, vec3 lightDir) {
    return max(0.0, dot(normalize(normal), normalize(lightDir)));
}

// Phong specular lighting
float specular(vec3 normal, vec3 lightDir, vec3 viewDir, float shininess) {
    vec3 reflectDir = reflect(-normalize(lightDir), normalize(normal));
    float spec = pow(max(0.0, dot(normalize(viewDir), reflectDir)), shininess);
    return spec;
}

// Fresnel effect
float fresnel(vec3 normal, vec3 viewDir, float power) {
    return pow(1.0 - max(0.0, dot(normalize(normal), normalize(viewDir))), power);
} 