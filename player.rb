require_relative 'point'
require_relative 'velocity'

class Player
  BASE_SPEED = 300.0
  RADIUS = 10.0

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

  def colliding(other_player, within: 1)
    new_player_position = move(within)
    new_other_position = other_player.move(within)

    return 1 if new_player_position.colliding?(new_other_position, radius: RADIUS)
    intersect(new_player_position, new_other_position, other_player, within: within)
  end

  def dodge(bullets)
    bullet = bullets.first
    bullet.angle + Math::PI / 2
  end

  def dodge_players(player)
    player.angle + Math::PI / 2
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
    world.bullets.count { |bullet| bullet.player_id == id } == 5
  end

  private

  def intersect(new_player_position, new_other_position, other_player, within:)
    a1 = new_player_position.x - position.x
    b1 = new_player_position.y - position.y
    c1 = a1 * position.x + b1 * position.y

    a2 = new_other_position.x - other_player.position.x
    b2 = new_other_position.y - other_player.position.y
    c2 = a2 * other_player.position.x + b2 * other_player.position.y

    det = a1.to_f * b2 - a2 * b1

    return nil if det == 0

    intersection_point = Point.new(
      (b2 * c1 - b1 * c2) / det,
      (a1 * c2 - a2 * c1) / det
    )
    player_distance = intersection_point.distance(position)
    other_distance = intersection_point.distance(other_player.position)

    other_time = other_distance / other_player.velocity.speed
    player_time = player_distance / velocity.speed

    player_time if other_time == player_time && player_time <= within
  end
end
