components {
  id: "highlight"
  component: "/shaders/highlight/highlight.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_image_1\"\n"
  "material: \"/shaders/highlight/highlight.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlases/sprites.atlas\"\n"
  "}\n"
  ""
}
