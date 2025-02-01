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
