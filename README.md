<think>
I'll create a comprehensive README.md file for the GitHub repository that explains the energy ball shader project. This should include:

1. Overview of the project
2. File structure and explanation
3. Implementation details
4. How to use the shader in a Defold project
5. Customization options
6. Credits/acknowledgments

I'll make it visually appealing with proper Markdown formatting, including headers, code blocks, and possibly a table of contents.
</think>

# Defold Energy Ball Shader

A high-quality energy ball shader implementation for the Defold game engine. This project provides a customizable, transparent energy ball effect with dynamic lightning and glow effects, perfect for magic spells, projectiles, or UI elements in your game.

![Energy Ball Shader](https://i.imgur.com/example.gif) *(Add your own screenshot/gif here)*

## Features

- Beautiful energy ball effect with dynamic lightning
- Fully transparent background for seamless integration
- Customizable parameters (size, colors, lightning behavior)
- Screen resolution-independent (maintains circular shape)
- Optimized for performance
- Compatible with OpenGL 3.3+ and SPIR-V
- Reusable shader utility library

## Structure

```
├── shaders/
│   ├── energy_ball/
│   │   ├── energy_ball.fp       # Fragment program
│   │   ├── energy_ball.vp       # Vertex program
│   │   └── energy_ball.material # Material configuration
│   └── util/
│       └── shader_lib.glsl      # Shared utility functions
├── scripts/
│   └── energy_ball.lua          # Control script
└── docs/
    ├── ai/
    │   └── knowledges.md        # Documentation and notes
    ├── basic-SPIR-V-Shader-requirements.fp  # SPIR-V fragment shader guide
    └── basic-SPIR-V-Shader-requirements.vp  # SPIR-V vertex shader guide
```

## Implementation Details

The energy ball shader creates a vibrant, pulsating energy effect with these key components:

1. **Core Glow**: A central bright core that fades to a purple outer glow
2. **Dynamic Lightning**: Electric arcs that animate outward from the center
3. **Normal Mapping**: Using a noise texture to create depth and detail
4. **Transparent Background**: Alpha channel support for seamless integration

The implementation is based on GLSL 330 with Defold-specific adaptations.

## Documentation

This project includes comprehensive documentation to help you understand and use the shaders:

- **knowledges.md**: Detailed notes on shader implementation techniques, including color palettes, optimization tips, and conversion guides.
- **basic-SPIR-V-Shader-requirements.fp/.vp**: Example code and requirements for SPIR-V compatibility in both fragment and vertex shaders, which is essential when targeting platforms that use the Vulkan graphics API.

## Usage

### Setup in Defold

1. Copy the shader files to your project
2. Create a game object with a sprite component
3. Apply the energy_ball.material to your sprite
4. Add the energy_ball.lua script to your game object
5. Add a noise texture for normal mapping

### Example Game Object

```lua
-- Example game.project component definition
components {
  id: "energy_ball"
  component: "/scripts/energy_ball.lua"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/sprites.atlas\"\n"
  "default_animation: \"white\"\n"
  "material: \"/shaders/energy_ball/energy_ball.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
}
```

### Drag and Drop Support

To add drag-and-drop functionality, add a drag controller script to your game object:

```lua
-- Example drag controller script
function init(self)
  -- Setup input handling
  self.dragging = false
  self.drag_offset = vmath.vector3()
end

function on_input(self, action_id, action)
  if action_id == hash("touch") then
    local pos = go.get_position()
    
    if action.pressed then
      -- Check if touch is within the energy ball radius
      local dist = vmath.length(vmath.vector3(action.x, action.y, 0) - pos)
      if dist < 100 then  -- Adjust based on your ball size
        self.dragging = true
        self.drag_offset.x = pos.x - action.x
        self.drag_offset.y = pos.y - action.y
      end
    elseif action.released then
      self.dragging = false
    end
    
    if self.dragging and action.touch then
      -- Update position while dragging
      go.set_position(vmath.vector3(
        action.x + self.drag_offset.x,
        action.y + self.drag_offset.y,
        pos.z
      ))
    end
  end
  
  return self.dragging
end
```

## Customization

You can customize the energy ball by modifying these parameters in the material file or via script:

| Parameter | Description |
|-----------|-------------|
| ball_params.y | Ball radius/size |
| distortion.xy | Distortion amplitude |
| distortion.z | Distortion frequency |
| lightning_params1.x | Number of lightning lines |
| lightning_params2.y | Lightning thickness |
| lightning_params3.y | Lightning oscillation speed |
| lightning_color | Lightning RGB color and intensity |

### Example Script Customization

```lua
-- Change the energy ball size
go.set("#sprite", "ball_params.y", 0.7)  -- Larger ball

-- Change lightning color to blue
go.set("#sprite", "lightning_color", vmath.vector4(0.2, 0.4, 1.0, 0.8))

-- Animate parameters
go.animate("#sprite", "distortion.z", go.PLAYBACK_LOOP_PINGPONG, 
          8.0, go.EASING_INOUTSINE, 2.0)
```

## Shader Utility Library

This project includes a reusable shader utility library (`shader_lib.glsl`) with common functions for:

- Color palettes (based on Inigo Quilez's techniques)
- Noise and random functions
- Drawing utilities
- Distortion effects
- Lighting calculations

You can include this library in your own shaders:

```glsl
#include "/shaders/util/shader_lib.glsl"
```

## Requirements

- Defold 1.2.175 or newer
- Graphics card with OpenGL 3.3+ support

## Credits

- Original energy ball concept inspired by [ShaderToy - Energy Ball by snakebyte](https://www.shadertoy.com/view/lfycz3)
- Color palette techniques based on [Inigo Quilez's work](https://iquilezles.org/articles/palettes/)
- Developed for the Defold game engine (https://defold.com/)

## License

This project is available under the MIT License. See the LICENSE file for details.

---

*Feel free to contribute improvements or report issues!*
