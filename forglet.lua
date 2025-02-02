function make_forglet(pos_x, pos_y, target)
    local forglet = make_rect(pos_x, pos_y, 3, 3, 11)  -- green square
    forglet.target = target
    forglet.hop_speed = 0.5 -- tiny hop speed
    forglet.facing = 1
    forglet:set_tag("forglet", true)

    -- Update: when "down" (btn3) is pressed and on ground, hop toward target
    forglet.update_func = function(self)
      dist = abs(self.target.x - self.x)
      self.facing = (self.target.x >= self.x) and 1 or -1

      if btn(3) and self:is_grounded() and dist > 10 then
        local dx = self.target.x - self.x
        local dy = self.target.y - self.y
        local d = sqrt(dx*dx + dy*dy)
        if d > 0 then
          self.x_vel = self.facing * self.hop_speed
          self.y_vel = -self.hop_speed
        end
        self:set_grounded(false)
      end
      -- Always face toward target


      if self:is_grounded() then
        self.x_vel = 0
      end
    end

    -- Wrap the base draw to add a 1x1 black eye in the facing direction
    local base_draw = forglet.draw_func
    forglet.draw_func = function(self)
      base_draw(self)  -- draw the 3x3 square
      if self.facing == 1 then
        pset(self.x + 2, self.y - 1, 0)
        pset(self.x, self.y - 1, 0)
      else
        pset(self.x - 2, self.y - 1, 0)
        pset(self.x, self.y - 1, 0)
      end
    end

    return forglet
  end
