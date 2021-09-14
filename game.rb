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

    else
      colliding_bullets = world.bullets_colliding(within: 2)
      colliding_players = world.players_colliding(within: 2)
      colliding_entities = colliding_players + colliding_bullets
      current_player = world.current_player

      if colliding_entities.any?
        dodge_angle = current_player.dodge_entity(colliding_entities)
        nearest_entity = world.nearest_entity(colliding_entities)
        distance = current_player.distance(nearest_entity)
        duration = 1

        if current_player.out_of_bullet?(world)
          duration = 2
        elsif colliding_players.any? && nearest_player = world.nearest_entity(colliding_players)
          remaining_bullet = current_player.remaining_bullet(world)

          if nearest_player.out_of_bullet?(world) && remaining_bullet > 0
            shoot(world, nearest_player, count: [2, remaining_bullet].min)
          else
            duration = 2
          end
        end

        run(world, dodge_angle, 1, duration: duration)
      elsif nearest_player = world.nearest_player
        distance = current_player.distance(nearest_player)

        if distance > 300
          angle = current_player.chase(nearest_player)
          run(world, angle, 1, duration: 1)
        elsif distance < 100 && (!nearest_player.out_of_bullet?(world) || current_player.out_of_bullet?(world))
          angle = current_player.dodge_entity([nearest_player])
          run(world, angle, 1, duration: 2)
        else
          remaining_bullet = current_player.remaining_bullet(world)
          shoot(world, nearest_player, count: [remaining_bullet, 2].min)
        end
      else
        rotate(world, nil)
      end
    end

    command = world.commands.shift
    world.commands.concat(command.next) if command.next
    command
  end

  def self.shoot(world, nearest_player, count: 1)
    angle = world.current_player.chase(nearest_player)

    if angle != world.current_player.angle && valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    end

    world.commands.concat([Shoot.new] * count)
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
