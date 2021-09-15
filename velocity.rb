require_relative 'point'

class Velocity
  attr_reader :angle, :speed

  def initialize(angle, speed)
    @angle = angle
    @speed = speed
  end

  def *(seconds)
    Velocity.new(angle, speed * seconds)
  end

  def +(entity)
    case entity
    when Point
      Point.new(
        entity.x + Math.cos(angle) * speed,
        entity.y + Math.sin(angle) * speed
      )
    when Velocity
      new_x = Math.cos(angle) * speed + Math.cos(entity.angle) * entity.speed
      new_y = Math.sin(angle) * speed + Math.sin(entity.angle) * entity.speed
      new_angle = Math.atan(new_y / new_x)
      new_speed = Math.sqrt(new_x*new_x + new_y*new_y)
      Velocity.new(new_angle, new_speed)
    else
      raise "Velocity + #{entity.class} is not support"
    end
  end
end
