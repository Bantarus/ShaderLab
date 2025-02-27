components {
  id: "vortex"
  component: "/shaders/vortex/vortex.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_image_1\"\n"
  "material: \"/shaders/vortex/vortex.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlases/sprites.atlas\"\n"
  "}\n"
  ""
}
