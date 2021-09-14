class Game
  def self.update(world, data)
    world ||= World.new

    world.event = data['e']

    case world.event
    when World::ID
      world.current_player_id = data['data']
    when World::TEAM
      world.players = data['data']
    when World::STATE
      world.update_state(data['data'])
    else
      puts "Cannot handle #{data}"
    end

    world
  end

  def self.decide(world)
    if world.preparing? || world.dead?
      noop(world)
    elsif world.commands.any?
      # do nothing

    elsif (bullets = world.bullets_colliding(within: 2)).any?
      world.commands.push(Dodge.new(world, bullets))

    elsif (players_with_time = world.players_colliding(within: 1)).any?
      nearest, time_to_colliding = players_with_time.sort { |_, time| -time }.first

      if nearest.out_of_bullet?(world)
        shoot(world, nearest)
      end

      angle = world.current_player.dodge_players(nearest)
      run(world, angle, 1, duration: 2)

    else
      nearest_player = world.nearest_player

      if nearest_player
        current_player = world.current_player
        distance = current_player.distance(nearest_player)

        if distance > 300
          angle = current_player.chase(nearest_player)
          run(world, angle, 1, duration: 1)
        elsif distance < 100
          if nearest_player.out_of_bullet?(world)
            shoot(world, nearest)
          else
            angle = world.current_player.dodge_players(nearest_player)
            run(world, angle, 1, duration: 2)
          end
        else
          shoot(world, nearest_player)
        end
      else
        rotate(world, nil)
      end
    end

    command = world.commands.shift
    world.commands.concat(command.next) if command.next
    command
  end

  def self.shoot(world, nearest_player)
    angle = world.current_player.chase(nearest_player)

    if angle != world.current_player.angle && valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    end

    world.commands.push(Shoot.new)
  end

  def self.rotate(world, angle)
    if valid_angle?(angle) && angle != world.current_player.angle
      world.commands.push(Rotate.new(angle: angle))
    else
      world.commands.push(Rotate.new(angle: world.current_player.angle))
    end
  end

  def self.run(world, angle, throttle, duration:)
    if valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    else
      world.commands.push(Rotate.new(angle: world.current_player.angle))
    end

    world.commands.concat([Run.new(throttle: throttle)] * duration)
  end

  def self.noop(world)
    world.commands.push(Noop.new)
  end

  def self.valid_angle?(angle)
    angle != nil && angle != Float::NAN
  end
end
