components {
  id: "outline"
  component: "/shaders/outline/outline.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_image_1\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlases/sprites.atlas\"\n"
  "}\n"
  ""
}
