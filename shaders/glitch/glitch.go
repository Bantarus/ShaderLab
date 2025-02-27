components {
  id: "glitch"
  component: "/shaders/glitch/glitch.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_image_1\"\n"
  "material: \"/shaders/glitch/glitch.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlases/sprites.atlas\"\n"
  "}\n"
  ""
} 