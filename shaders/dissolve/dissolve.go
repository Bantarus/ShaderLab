components {
  id: "dissolve"
  component: "/shaders/dissolve/dissolve.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_image_1\"\n"
  "material: \"/shaders/dissolve/dissolve.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlases/sprites.atlas\"\n"
  "}\n"
  ""
}
