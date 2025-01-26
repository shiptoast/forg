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

function Entity:get_tag(tag)
  return self.tags[tag]
end

function Entity:set_tag(tag, val)
  self.tags[tag] = val
end

function Entity:del_tag(tag)
  self.tags[tag] = nil
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

function make_shades(pos_x, pos_y)
  shades = make_rect(pos_x, pos_y, 8, 3, 3)
  old_draw_func = shades.draw_func
  shades.draw_func = function(self)
    -- old_draw_func(self)
    spr(4, self.x -5, self.y-3)
    spr(5, self.x + 3, self.y-3)
  end
  return shades
end

function make_camera(pos_x, pos_y)
  camera = make_rect(pos_x, pos_y, 8, 4, 3)
  old_draw_func = camera.draw_func
  camera.draw_func = function(self)
    -- old_draw_func(self)
    spr(2, self.x-4, self.y-5)
    spr(3, self.x+4, self.y-5)
  end
  return camera
end

function make_watch(pos_x, pos_y)
  watch = make_rect(pos_x, pos_y, 4, 4, 3)
  old_draw_func = watch.draw_func
  watch.draw_func = function(self)
    -- old_draw_func(self)
    spr(1, self.x-2, self.y-5)
  end
  return watch
end

function make_random_obj()
  local x = rnd(tank_x_end - tank_x_start) + tank_x_start
  local y = 50 + rnd(20)
  local width = flr(rnd(5)) + 2
  local height = flr(rnd(5)) + 2
  local color = flr(rnd(15)) + 1
  local is_watch = rnd(1) <= 0.3
  local is_cam = rnd(1) <= 0.2
  local is_shades = rnd(1) <= 0.1
  -- local is_round = rnd(1) > 0.5

  if is_shades then
    grabbable = make_shades(x, y)
  elseif is_cam then
    grabbable = make_camera(x, y)
  elseif is_watch then
    grabbable = make_watch(x, y)
  else
    grabbable = make_rect(x, y, width, height, color)
  end
  return grabbable
end

function aabb_collision(obj1, obj2)
  return obj1.x - obj1.width / 2 < obj2.x + obj2.width / 2 and -- obj1's left is to the left of obj2's right
         obj1.x + obj1.width / 2 > obj2.x - obj2.width / 2 and -- obj1's right is to the right of obj2's left
         obj1.y - obj1.height / 2 < obj2.y + obj2.height / 2 and -- obj1's top is above obj2's bottom
         obj1.y + obj1.height / 2 > obj2.y - obj2.height / 2    -- obj1's bottom is below obj2's top
end

function check_collision(obj1, obj2)
  return aabb_collision(obj1, obj2)
end

function resolve_aabb_collision(obj1, obj2)
  -- Calculate half widths and heights
  local half_width1, half_width2 = obj1.width / 2, obj2.width / 2
  local half_height1, half_height2 = obj1.height / 2, obj2.height / 2

  -- Calculate the overlap
  local overlap_x = (half_width1 + half_width2) - abs(obj1.x - obj2.x)
  local overlap_y = (half_height1 + half_height2) - abs(obj1.y - obj2.y)

  -- Only resolve if there is a collision
  if overlap_x > 0 and overlap_y > 0 then
    if overlap_x < overlap_y then
      -- Resolve on x-axis
      obj1.x_vel = 0
      if obj1.x < obj2.x then
        obj1.x -= overlap_x
      else
        obj1.x += overlap_x
      end
      return "horizontal"
    else
      -- Resolve on y-axis
      obj1.y_vel = 0
      if obj1.y < obj2.y then
        obj1.y -= overlap_y
      else
        obj1.y += overlap_y
      end
      return "vertical"
    end
  end
end

function resolve_collision(obj1, obj2)
  return resolve_aabb_collision(obj1, obj2)
end

function _init()
  -- game balance tunables

  cursor_rotation_speed = 4 -- degrees per tick

  -- other stuff

  frog_x = 64
  frog_y = 87
  frog_jump_speed = -4
  frog_vertical_speed = 0
  frog_horizontal_speed = 0
  frog_on_ground = false
  frog_direction = 1

  btns_pressed = {}

  tank_x_start = 38
  tank_x_end = 90
  tank_y_start = 64
  tank_y_end = 96
  gravity = 0.08
  drag = 0.05

  cursor_angle = 0
  cursor_distance = 32

  tongue_active = false
  tongue_retracting = false
  tongue_progress = 0
  tongue_max_progress = 120

  uncaught_objects = {}
  caught_objects = {}
  object_spawn_timer = 0
  object_spawn_interval = 90

  renderables = {}

  tank_left = make_rect(tank_x_start + 2, (tank_y_start + tank_y_end) / 2, 4, tank_y_end - tank_y_start, 7)
  add(renderables, tank_left)
  tank_right = make_rect(tank_x_end - 2, (tank_y_start + tank_y_end) / 2, 4, tank_y_end - tank_y_start, 7)
  add(renderables, tank_right)
  tank_bottom = make_rect((tank_x_start + tank_x_end) / 2, tank_y_end - 2, tank_x_end - tank_x_start, 4, 7)
  add(renderables, tank_bottom)
  tank_left:set_static(true)
  tank_right:set_static(true)
  tank_bottom:set_static(true)

  frog = make_rect(frog_x, frog_y, 4, 4, 11)
  add(renderables, frog)
end

function _update()
  local left_pressed = false
  local right_pressed = false
  for _, btn in ipairs(btns_pressed) do
    if btn == 1 then left_pressed = true end
    if btn == -1 then right_pressed = true end
  end

  if btn(0) and not left_pressed then add(btns_pressed, 1) end
  if not btn(0) and left_pressed then del(btns_pressed, 1) end

  if btn(1) and not right_pressed then add(btns_pressed, -1) end
  if not btn(1) and right_pressed then del(btns_pressed, -1) end

  local x_dir = 0
  if #btns_pressed >= 1 then x_dir = btns_pressed[#btns_pressed] end

  if not btn(4) and not btn(5) and frog:is_grounded() then
    cursor_angle = (cursor_angle + (x_dir * cursor_rotation_speed)) % 360
  end

  if not frog:is_grounded() then
    if btn(0) and frog.x_vel == 0 then frog.x_vel = min(-1, frog.x_vel) end
    if btn(1) and frog.x_vel == 0 then frog.x_vel =  max(1, frog.x_vel) end
  end

  if btn(4) and frog:is_grounded() then
    local cursor_x = frog.x + cos(cursor_angle / 360) * cursor_distance
    local cursor_y = frog.y + sin(cursor_angle / 360) * cursor_distance
    local hop_direction_x = cursor_x - frog.x
    local hop_direction_y = cursor_y - frog.y
    local hop_magnitude = sqrt(hop_direction_x^2 + hop_direction_y^2)
    frog.x_vel = (hop_direction_x / hop_magnitude) * 2
    frog.y_vel = (hop_direction_y / hop_magnitude) * 2
    frog:set_grounded(false)
  end

  if cursor_angle > 270 or cursor_angle < 65 then
    frog_direction = 1
  elseif cursor_angle >= 65 and cursor_angle < 115 then
    frog_direction = 0
  else
    frog_direction = -1
  end

  if frog:is_grounded() then
    frog.x_vel = 0
  else
    if frog.x_vel > 0 then
      frog.x_vel = max(0, frog.x_vel - drag)
    elseif frog.x_vel < 0 then
      frog.x_vel = min(0, frog.x_vel + drag)
    end
  end

  if btn(5) and not tongue_active and frog:is_grounded() then
    sfx(0, 0, 0, 5)
    tongue_active = true
    tongue_retracting = false
    tongue_progress = 0
  end

  if tongue_active then
    if tongue_retracting then
      tongue_progress -= 18
      if tongue_progress <= 0 then
        tongue_active = false
        tongue_retracting = false
      end
    else
      tongue_progress += 18

      local tongue_x = frog.x + cos(cursor_angle / 360) * (tongue_progress * cursor_distance / tongue_max_progress)
      local tongue_y = frog.y + sin(cursor_angle / 360) * (tongue_progress * cursor_distance / tongue_max_progress)

      for obj in all(uncaught_objects) do
        if not tongue_retracting then
          if aabb_collision({ x = tongue_x, y = tongue_y, width = 2, height = 2 }, obj) then
            obj.caught = true
            obj:del_tag("grabbable")
            add(caught_objects, obj)
            del(uncaught_objects, obj)
            tongue_retracting = true
            sfx(0, 0, 7, 7)
          end
        end
      end

      if tongue_progress >= tongue_max_progress then
        tongue_retracting = true
      end
    end

    for obj in all(caught_objects) do
      if obj.caught then
        local progress = max(0, tongue_progress)
        obj.x = frog.x + frog_direction + cos(cursor_angle / 360) * (progress * cursor_distance / tongue_max_progress)
        obj.y = frog.y + sin(cursor_angle / 360) * (progress * cursor_distance / tongue_max_progress)

        if tongue_progress <= 0 then
          obj.caught = false
          drop_offset = 6 + rnd(2)
          if frog_direction == 1 or (frog_direction == 0 and cursor_angle < 90) then
            obj.x = frog.x + drop_offset
          else
            obj.x = frog.x - drop_offset
          end

          local stack_height = tank_y_end - obj.height / 2
          for o in all(caught_objects) do
            if abs(o.x - obj.x) < (obj.width + o.width) / 2 then
              stack_height = min(stack_height, o.y - o.height / 2 - obj.height / 2)
            end
          end
          obj.y = stack_height
        end
      end
    end
  end

  -- Spawn objects periodically
  object_spawn_timer += 1
  if object_spawn_timer >= object_spawn_interval then
    object_spawn_timer = 0

    -- Create a round uncaught object
    local obj = make_random_obj()
    obj:set_tag("grabbable", true)
    obj.caught = false -- Add a caught state to the object
    obj.timer = object_spawn_interval -- Timer for disappearance
    add(uncaught_objects, obj)
    add(renderables, obj)
  end

  for obj in all(uncaught_objects) do
    obj.timer -= 1
    if obj.timer == 0 then
      del(uncaught_objects, obj)
      del(renderables, obj)
      obj = nil
    end
  end

  for obj in all(renderables) do
    if not (obj:is_static() or obj:is_grounded() or obj:get_tag("grabbable")) then
      for other in all(renderables) do
        if obj != other then
          is_touching_object = check_collision(obj, other)
          if is_touching_object and other != frog then
            obj:del_tag("grabbable")
            obj.caught = false
            del(caught_objects, obj)
            dir = resolve_collision(obj, other)
            if dir == "vertical" and (other == tank_bottom or other:is_grounded()) and other.y > obj.y then
              obj.y -= 1;
              obj:set_grounded(true)
            end
          end
        end
      end

      if not (obj:is_grounded() or obj:is_static() or obj:get_tag("grabbable") == true) then
        obj.y_vel += gravity
      end
    end

    obj.x += obj.x_vel
    obj.y += obj.y_vel
  end

  if frog.y_vel < 0 then
    frog:set_grounded(false)
  end
end

function _draw()
  cls(12)

  for obj in all(renderables) do
    if obj != frog then
      obj:draw()
    end
  end

  frog:draw()

  if frog_direction == -1 then
    rectfill(frog.x - 2, frog.y - 3, frog.x - 2, frog.y - 3, 0)
    rectfill(frog.x + 1, frog.y - 2, frog.x + 2, frog.y - 1, 0)
  elseif frog_direction == 0 then
    rectfill(frog.x - 2, frog.y - 2, frog.x - 2, frog.y - 2, 0)
    rectfill(frog.x + 2, frog.y - 2, frog.x + 2, frog.y - 2, 0)
  else
    rectfill(frog.x - 2, frog.y - 2, frog.x - 1, frog.y - 1, 0)
    rectfill(frog.x + 2, frog.y - 3, frog.x + 2, frog.y - 3, 0)
  end

  -- if frog_direction <1 then
  --   spr(4, frog.x - 6, frog.y - 5)
  --   spr(5, frog.x + 2, frog.y - 5)
  -- else
  --   spr(5, frog.x - 9, frog.y - 5, 1, 1, true)
  --   spr(4, frog.x - 1, frog.y - 5, 1, 1, true)
  -- end

  local cursor_x = frog.x + cos(cursor_angle / 360) * cursor_distance
  local cursor_y = frog.y + sin(cursor_angle / 360) * cursor_distance

  circ(cursor_x, cursor_y, 2, 8)

  if tongue_active then
    local progress = max(0, tongue_progress)
    local tongue_x = frog.x + cos(cursor_angle / 360) * (progress * cursor_distance / tongue_max_progress)
    local tongue_y = frog.y + sin(cursor_angle / 360) * (progress * cursor_distance / tongue_max_progress)

    line(frog.x + frog_direction, frog.y, tongue_x, tongue_y, 8)
  end

  print("why are arrays 1-indexed", 1, 1, 7)
end