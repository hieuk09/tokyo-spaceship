class Bullet
  RADIUS = 2.0
  SPEED = 600.0

  attr_reader :position, :velocity, :player_id

  def initialize(data)
    @position = Point.new(data['x'], data['y'])
    @id = data['id']
    @player_id = data['player_id']
    @velocity = Velocity.new(data['angle'], SPEED)
  end

  def colliding?(player, within: 1)
    (0..(within * 100)).any? do |i|
      new_bullet_position = move(i / 100.0)
      new_player_position = player.move(i / 100.0)

      new_bullet_position.colliding?(new_player_position, radius: RADIUS)
    end
  end

  def move(within)
    position + velocity * within
  end

  def angle
    velocity.angle
  end
end
