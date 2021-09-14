require_relative 'point'
require_relative 'velocity'

class Player
  BASE_SPEED = 300.0
  RADIUS = 10.0
  MAX_CONCURRENT_BULLET = 5

  attr_reader :angle, :throttle, :position, :velocity, :id, :player_name

  def initialize(data)
    @id = data['id']
    @player_name = data['player_name']
    @angle = data['angle']
    @throttle = data.fetch('throttle', 0)
    @position = Point.new(data['x'], data['y'])
    @velocity = Velocity.new(@angle, @throttle * BASE_SPEED)
  end

  def move(in_seconds)
    @position + @velocity * in_seconds
  end

  def colliding?(other_player, within: 1)
    (0..(within * 100)).any? do |i|
      new_player_position = move(i / 100.0)
      new_other_position = other_player.move(i / 100.0)

      new_other_position.colliding?(new_player_position, radius: RADIUS)
    end
  end

  def dodge_entity(entities)
    entities.inject(Velocity.new(0.0, 0.0)) do |sum, entity|
      sum + entity.velocity
    end.angle + Math::PI / 2
  end

  def distance(player)
    position.distance(player.position)
  end

  def chase(player)
    new_x = player.position.x - position.x
    new_y = player.position.y - position.y

    if new_x == 0
      Math::PI + Math.atan(new_y / new_x)
    elsif new_x < 0
      Math::PI + Math.atan(new_y / new_x)
    elsif new_x > 0 && new_y < 0
      2 * Math::PI + Math.atan(new_y / new_x)
    else
      Math.atan(new_y / new_x)
    end
  end

  def out_of_bullet?(world)
    remaining_bullet(world) == 0
  end

  def remaining_bullet(world)
    MAX_CONCURRENT_BULLET - world.bullets.count { |bullet| bullet.player_id == id }
  end
end
