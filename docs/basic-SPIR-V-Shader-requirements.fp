#version 330

////////////////////////////////////////////////////////////////////////////////
// Inputs
////////////////////////////////////////////////////////////////////////////////

// Inputs should of course match the vertex shader's outputs.
in vec2 var_texcoord0;
flat in float flat_damage;

////////////////////////////////////////////////////////////////////////////////
// Uniforms
////////////////////////////////////////////////////////////////////////////////

// As mentioned in the vertex shader, a `sampler2D` is an opaque uniform.
// Remember that opaque unforms do not require a uniform block.
uniform sampler2D texture_sampler;

////////////////////////////////////////////////////////////////////////////////
// Outputs
////////////////////////////////////////////////////////////////////////////////

// The final color of the fragment was set with `glFragColor`.
// Instead, our SPIR-V shaders should list a single output variable, which acts as the final color.
out vec4 color;

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

void main()
{
    // As the character takes damage, the red color rises upward and fills the brick.
    // Ignoring atlas-related coordinate complications,
    // we simply need to set the fragment color to red if its y texture coordinate is less than `damage`.
    // For example, if `damage` is 0.5 (the character is 50% dead), then the red color will reach halfway up the brick.
    // We can employ this trick because texture coordinates are normalized from 0.0 to 1.0, as is `damage`.
    if (var_texcoord0.y < damage)
    {
        // Mix the original white color with a shade of red.
        // If `damage` is low, it will be a dark shade of red.
        // If `damage` is high, it will be a light shade of red.
        color = texture(texture_sampler, var_texcoord0) * vec4(flat_damage, 0, 0, 0);
    }
    else
    {
        // Simply use the original white color.
        color = texture(texture_sampler, var_texcoord0);
    }
}