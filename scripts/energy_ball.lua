local function update_shader(self, dt)
    -- Update time
    self.time = self.time + dt
    go.set("#sprite", "time.x", self.time)
    
    -- Other updates can be added here
end

function init(self)
    -- Initialize time
    self.time = 0
    
    -- Set resolution and account for texture aspect ratio
    local width, height = window.get_size()
    local texture_width, texture_height = 234, 119  -- The actual texture dimensions
    local texture_ratio = texture_width / texture_height
    
    -- Important: Pass texture ratio in the z component to maintain proper shape
    -- The shader uses this value for aspect ratio calculations
    go.set("#sprite", "resolution", vmath.vector4(width, height, texture_ratio, 0))
end

function update(self, dt)
    update_shader(self, dt)
end

function on_message(self, message_id, message, sender)
    -- Handle window resizing
    if message_id == hash("window_resized") then
        local width = message.width
        local height = message.height
        local texture_ratio = 234.0 / 119.0  -- Texture aspect ratio
        go.set("#sprite", "resolution", vmath.vector4(width, height, texture_ratio, 0))
    end
end 