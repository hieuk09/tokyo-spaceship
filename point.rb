class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def +(velocity)
    Point.new(
      x + Math.cos(velocity.angle) * velocity.speed,
      y + Math.sin(velocity.angle) * velocity.speed
    )
  end

  def colliding?(player_position, radius:)
    distance(player_position) < Player::RADIUS + radius
  end

  def distance(other_position)
    dx = x - other_position.x
    dy = y - other_position.y
    Math.sqrt(dx * dx + dy * dy)
  end
end
