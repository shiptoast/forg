Entity = {}
Entity.__index = Entity

function Entity:new(pos_x, pos_y, width, height, color, draw_func, shape_type)
  local entity = setmetatable({
    x = pos_x,
    y = pos_y,
    width = width,
    height = height,
    color = color,
    debug_color = nil,
    draw_func = function(self)
      draw_func(self)
    end,
    shape_type = shape_type,
    x_vel = 0,
    y_vel = 0,
    tags = {},
    child_objects = {}
  }, Entity)
  return entity
end

function Entity:draw()
  self.draw_func(self)
end

function Entity:update()
  self.update_func(self)
end

function Entity:get_tag(tag)
  return self.tags[tag]
end

function Entity:set_tag(tag, val)
  self.tags[tag] = val
end

function Entity:del_tag(tag)
  self.tags[tag] = nil
end

function Entity:has_tag(tag)
  return self.tags[tag] != nil
end

function Entity:set_static(is_static)
  self:set_tag("static", is_static)
end

function Entity:is_static()
  return self:get_tag("static") == true
end

function Entity:set_grounded(is_grounded)
  self:set_tag("grounded", is_grounded)
end

function Entity:is_grounded()
  return self:get_tag("grounded") == true
end



function make_rect(pos_x, pos_y, width, height, color)
  return Entity:new(
    pos_x,
    pos_y,
    width,
    height,
    color,
    function(self)
    if self.debug_color != nil then draw_color = self.debug_color else draw_color = self.color end
    rectfill(
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.x + self.width / 2,
        self.y + self.height / 2,
        draw_color
    )
    end,
    "rect"
  )
end
