components {
  id: "energy_ball"
  component: "/shaders/energy_ball/energy_ball.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"energy_ball_sampler\"\n"
  "material: \"/shaders/energy_ball/energy_ball.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler0\"\n"
  "  texture: \"/atlases/textures_0.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 2.0
    y: 2.0
  }
}
