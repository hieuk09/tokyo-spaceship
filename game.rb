require_relative 'player'
require_relative 'population'

class Game
  attr_reader :chosen_hero, :population, :logger

  def initialize(logger:)
    # hash sort by score ascending
    @population = Population.new(logger: logger)
    @logger = logger
  end

  def update(world, data)
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

  def decide(world)
    if world.commands.any?
      # do nothing
    elsif world.preparing? || world.dead?
      # update population with the score hero gets during their run
      if world.preparing? || @alive
        population.update(chosen_hero, world.current_score - current_score)
        @alive = false
        @chosen_hero = population.choose_hero
        @current_score = world.current_score
        logger.info(hero: chosen_hero)
        logger.info(population: population.population)
      end
      noop(world)

    else
      @alive = true
      # Parameters:
      #- Considered Radius
      #- Weight of bullet colliding
      #- Weight of player colliding
      #- Weight of chance to shoot
      #- Weight of chance to chase
      #- Weight of each type of chase:
        #- Nearest
        #- Highest Score
        #- Lowest Score
        #- Crowdest
      #- Weight of running away

      #Output:
      #- Which sequence of actions to take: Dodge / Chase / Shoot / Run?
      #- If Dodge:
        #- How long?

      #- Chase:
        #- Distance to start shooting
        #- Angle
        #- Throttle
      #- Shoot
        #- Angle
        #- Throttle
        #- Number of shot
      me = world.current_player

      # dodge
      colliding_bullets = world.bullets_colliding(within: chosen_hero[:bullet_duration])
      colliding_players = world.players_colliding(within: chosen_hero[:player_duration])
      dodging_weight = colliding_bullets.sum { |bullet| chosen_hero[:bullet_dodging_radius] / me.distance(bullet) } * chosen_hero[:weight_of_bullet_colliding]
      dodging_weight += colliding_players.sum { |player| chosen_hero[:player_dodging_radius] / me.distance(player) } * chosen_hero[:weight_of_player_colliding]

      # shoot | chase
      no_bullet_players = colliding_players.select { |player| player.out_of_bullet?(world) }
      no_bullet_players_sum_distance = no_bullet_players.sum { |player| player.distance(me) }
      no_bullet_player_ids = no_bullet_players.map(&:id)
      real_shoot_chance = chosen_hero[:weight_of_chance_to_shoot] / chosen_hero[:shooting_radius]
      real_chase_chance = chosen_hero[:weight_of_chance_to_chase] / chosen_hero[:chasing_radius]
      shoot_weight = no_bullet_players_sum_distance * real_shoot_chance
      chase_weight = no_bullet_players_sum_distance * real_chase_chance

      nearby_players = world.nearby_players(within: chosen_hero[:considered_radius]).select { |player| !no_bullet_player_ids.include?(player.id) }
      nearby_players_sum_distance = nearby_players.sum { |player| player.distance(me) }
      shoot_weight += nearby_players_sum_distance * real_shoot_chance
      chase_weight += nearby_players_sum_distance * real_chase_chance

      max_weight = [dodging_weight, shoot_weight, chase_weight].max

      logger.info(dodge: dodging_weight, shoot: shoot_weight, chase: chase_weight)

      if max_weight == dodging_weight
        dodge(world, colliding_bullets + colliding_players, duration: chosen_hero[:dodge_duration])
      elsif max_weight == shoot_weight
        shoot(world, no_bullet_players + nearby_players, count: chosen_hero[:bullet_count])
      elsif max_weight == chase_weight
        chase(world, no_bullet_players + nearby_players, duration: chosen_hero[:chase_duration])
      else
        # do nothing
        noop(world)
      end
    end

    command = world.commands.shift
    world.commands.concat(command.next) if command.next
    command
  end

  private

  def current_score
    @current_score || 0
  end

  def shoot(world, players, count: 1)
    nearest_player = world.nearest_player(players)
    angle = world.current_player.chase(nearest_player)

    if angle != world.current_player.angle && valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    end

    world.commands.concat([Shoot.new] * count)
  end

  def dodge(world, entities, duration:)
    angle = world.current_player.dodge_entity(entities)

    if angle != world.current_player.angle && valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    end

    world.commands.concat([Run.new(throttle: 1)] * duration)
  end

  def chase(world, players, duration:)
    nearest_player = world.nearest_player(players)
    angle = world.current_player.chase(nearest_player)

    if angle != world.current_player.angle && valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    end

    world.commands.concat([Run.new(throttle: 1)] * duration)
  end

  def rotate(world, angle)
    if valid_angle?(angle) && angle != world.current_player.angle
      world.commands.push(Rotate.new(angle: angle))
    else
      world.commands.push(Rotate.new(angle: world.current_player.angle))
    end
  end

  def run(world, angle, throttle, duration:)
    if valid_angle?(angle)
      world.commands.push(Rotate.new(angle: angle))
    else
      world.commands.push(Rotate.new(angle: world.current_player.angle))
    end

    world.commands.concat([Run.new(throttle: throttle)] * duration)
  end

  def noop(world)
    world.commands.push(Noop.new)
  end

  def valid_angle?(angle)
    angle != nil && angle != Float::NAN
  end
end
