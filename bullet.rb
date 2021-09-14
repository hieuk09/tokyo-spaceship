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
    new_player_position = player.move(within)
    new_bullet_position = move(within)

    new_bullet_position.colliding?(new_player_position, radius: RADIUS) ||
      intersect?(new_bullet_position, new_player_position, player, within: within)
  end

  def move(within)
    position + velocity * within
  end

  def angle
    velocity.angle
  end

  private

  def intersect?(new_bullet_position, new_player_position, player, within:)
    a1 = new_bullet_position.x - position.x
    b1 = new_bullet_position.y - position.y
    c1 = a1 * position.x + b1 * position.y

    a2 = new_player_position.x - player.position.x
    b2 = new_player_position.y - player.position.y
    c2 = a2 * player.position.x + b2 * player.position.y

    det = a1.to_f * b2 - a2 * b1

    return false if det == 0

    intersection_point = Point.new(
      (b2 * c1 - b1 * c2) / det,
      (a1 * c2 - a2 * c1) / det
    )
    bullet_distance = intersection_point.distance(position)
    player_distance = intersection_point.distance(player.position)

    bullet_time = bullet_distance / SPEED
    player_time = player_distance / player.velocity.speed

    # we don't compare bullet_time and player_time
    # because it's rarely equal, thus create too many false negatives
    #
    # technically, this is incorrect, but intersection calculation is flawed
    # when bullet and player is near
    player_time <= within || bullet_time <= within
  end
end
