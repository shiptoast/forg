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
  local color = flr(rnd(14)) + 1
  if color >= 12 then color += 1 end
  -- local is_watch = rnd(1) <= 0.3
  -- local is_cam = rnd(1) <= 0.2
  -- local is_shades = rnd(1) <= 0.1
  -- -- local is_round = rnd(1) > 0.5

  -- if is_shades then
  --   grabbable = make_shades(x, y)
  -- elseif is_cam then
  --   grabbable = make_camera(x, y)
  -- elseif is_watch then
  --   grabbable = make_watch(x, y)
  -- else
    grabbable = make_rect(x, y, width, height, color)
  -- end
  return grabbable
end

function _init()
  -- game balance tunables

  cursor_rotation_speed = 3 -- degrees per tick
  frog_move_speed = 0.7 -- pixels per tick

  frog_direction_influence = 25 -- degrees where frog faces fwd per quadrant

  -- other stuff

  frog_x = 64
  frog_y = 87
  frog_jump_speed = 2
  frog_vertical_speed = 0
  frog_horizontal_speed = 0
  frog_on_ground = false
  frog_direction = 1

  cursor_btns_pressed = {}
  frog_btns_pressed = {}

  tank_x_start = 18
  tank_x_end = 110
  tank_y_start = 64
  tank_y_end = 96
  gravity = 0.12
  drag = 0.05

  cursor_angle = 90
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

  froglet = make_froglet(frog_x + 20, frog_y, frog)
  add(renderables, froglet)

  froglet2 = make_froglet(frog_x + 20, frog_y, froglet)
  add(renderables, froglet2)

  froglet3 = make_froglet(frog_x + 20, frog_y, froglet2)
  add(renderables, froglet3)
end

function _update()
  -- X/O to aim cursor
  control_cursor()

  -- up to shoot tongue
  control_tongue()

  -- left/right to move frog
  control_frog()

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
        -- todo, add collision filters instead of this garbage
        if obj != other and not (obj:has_tag("froglet") and other:has_tag("froglet")) then
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

  froglet:update()
  froglet2:update()
  froglet3:update()
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

  print("frog ♥ froglets", 1, 1, 7)
end

function control_cursor()
  local left_pressed = false
  local right_pressed = false
  for _, btn in ipairs(cursor_btns_pressed) do
    if btn == 1 then left_pressed = true end
    if btn == -1 then right_pressed = true end
  end

  if btn(4) and not left_pressed then add(cursor_btns_pressed, 1) end
  if not btn(4) and left_pressed then del(cursor_btns_pressed, 1) end

  if btn(5) and not right_pressed then add(cursor_btns_pressed, -1) end
  if not btn(5) and right_pressed then del(cursor_btns_pressed, -1) end

  local x_dir = 0
  if #cursor_btns_pressed >= 1 then x_dir = cursor_btns_pressed[#cursor_btns_pressed] end

  cursor_angle = (cursor_angle + (x_dir * cursor_rotation_speed)) % 360

  -- right-facing
  local q1_bkpt = 90 - frog_direction_influence
  local q4_bkpt = 270 + frog_direction_influence
  local face_right = cursor_angle < q1_bkpt or cursor_angle > q4_bkpt
  -- left-facing
  local q2_bkpt = 90 + frog_direction_influence
  local q3_bkpt = 270 - frog_direction_influence
  local face_left = cursor_angle > q2_bkpt and cursor_angle < q3_bkpt

  if face_right then frog_direction = 1
  elseif face_left then frog_direction = -1
  else frog_direction = 0 end
end

function control_tongue()
  if btn(2) and not tongue_active then
    sfx(0, 0, 0, 5)
    tongue_active = true
    tongue_retracting = false
    tongue_progress = 0
  end
end

function control_frog()
  local left_pressed = false
  local right_pressed = false
  for _, btn in ipairs(frog_btns_pressed) do
    if btn == 1 then left_pressed = true end
    if btn == -1 then right_pressed = true end
  end

  if btn(1) and not left_pressed then add(frog_btns_pressed, 1) end
  if not btn(1) and left_pressed then del(frog_btns_pressed, 1) end

  if btn(0) and not right_pressed then add(frog_btns_pressed, -1) end
  if not btn(0) and right_pressed then del(frog_btns_pressed, -1) end

  local x_dir = 0
  if #frog_btns_pressed >= 1 then x_dir = frog_btns_pressed[#frog_btns_pressed] end

  frog.x_vel = frog_move_speed * x_dir

  -- frog input overrides cursor for facing direction
  if x_dir != 0 then frog_direction = x_dir end
end