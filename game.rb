require_relative 'player'

class Game
  INITIAL_POPULATION = {
    {
      considered_radius: 500.0,
      shooting_radius: 200.0,
      chasing_radius: 500.0,
      bullet_dodging_radius: 200.0,
      player_dodging_radius: 1848.3,
      bullet_duration: 2,
      player_duration: 2,
      dodge_duration: 2,
      bullet_count: 2,
      chase_duration: 1,
      weight_of_bullet_colliding: 10.0,
      weight_of_player_colliding: 8.0,
      weight_of_chance_to_shoot: 3.0,
      weight_of_chance_to_chase: 1.0
    } => 1,
    {
      considered_radius: 500.0,
      shooting_radius: 200.0,
      chasing_radius: 500.0,
      bullet_dodging_radius: 200.0,
      player_dodging_radius: 1849.7,
      bullet_duration: 2,
      player_duration: 2,
      dodge_duration: 2,
      bullet_count: 2,
      chase_duration: 1,
      weight_of_bullet_colliding: 10.0,
      weight_of_player_colliding: 8.0,
      weight_of_chance_to_shoot: 3.0,
      weight_of_chance_to_chase: 1.0
    } => 1
  }
  DISTANCE_TYPE = { type: Float, min: 100.0, max: 2000.0 }
  DURATION_TYPE = { type: Integer, min: 1, max: 5 }
  TICK_TYPE = { type: Integer, min: 1, max: 10 }
  BULLET_TYPE = { type: Integer, min: 1, max: Player::MAX_CONCURRENT_BULLET }
  WEIGHT_TYPE = { type: Float, min: 0.0, max: 100.0 }
  KEY_TYPE = {
    considered_radius: DISTANCE_TYPE,
    shooting_radius: DISTANCE_TYPE,
    chasing_radius: DISTANCE_TYPE,
    bullet_dodging_radius: DISTANCE_TYPE,
    player_dodging_radius: DISTANCE_TYPE,
    bullet_duration: DURATION_TYPE,
    player_duration: DURATION_TYPE,
    dodge_duration: TICK_TYPE,
    bullet_count: BULLET_TYPE,
    chase_duration: TICK_TYPE,
    weight_of_bullet_colliding: WEIGHT_TYPE,
    weight_of_player_colliding: WEIGHT_TYPE,
    weight_of_chance_to_shoot: WEIGHT_TYPE,
    weight_of_chance_to_chase: WEIGHT_TYPE
  }
  MAX_POPULATION_SIZE = 100
  MUTATION_RATE = 0.1 # 10% chance of one mutate
  MUTATION_TYPE = [:add, :substract, :min, :max, :average, :inverse]

  attr_reader :chosen_hero, :population, :logger

  def initialize(initial_population = INITIAL_POPULATION, logger:)
    # hash sort by score ascending
    @population = initial_population.dup
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
      update_population(world.current_score - current_score)
      logger.info(score: world.current_score - current_score)
      @chosen_hero = choose_hero
      @current_score = world.current_score
      logger.info(hero: chosen_hero)
      logger.info(population: population)
      noop(world)

    else
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

  def choose_hero(existing_hero = nil)
    population.reverse_each do |hero, _score|
      next if hero == existing_hero

      chosen = [hero, nil].sample

      return chosen if chosen
    end

    return (population.keys - [existing_hero].compact).sample
  end

  def need_mutation?
    population.count == 1 || SecureRandom.rand < MUTATION_RATE
  end

  def update_population(new_score)
    return if chosen_hero.nil?

    # avoid the case when score is negative due to restart
    new_score = [new_score, 0].max
    population[chosen_hero] = (population[chosen_hero] + new_score) / 2.0

    new_hero = need_mutation? ? mutate(chosen_hero) : breed

    while population.count >= MAX_POPULATION_SIZE || !population.include?(new_hero)
      population.shift
    end

    population[new_hero] ||= 0
    @population = population.sort_by { |_hero, score| score }.to_h
  end

  def mutate(chosen_hero)
    new_hero = chosen_hero.dup
    key = chosen_hero.keys.sample
    mutation_type = MUTATION_TYPE.sample

    new_hero[key] =
      case mutation_type
      when :add
        [new_hero[key] + 1, KEY_TYPE[key][:max]].min
      when :substract
        [new_hero[key] - 1, KEY_TYPE[key][:min]].max
      when :min
        KEY_TYPE[key][:min]
      when :max
        KEY_TYPE[key][:max]
      when :average
        (KEY_TYPE[key][:min] + KEY_TYPE[key][:max]) / 2
      when :inverse
        [KEY_TYPE[key][:max] - new_hero[key], KEY_TYPE[key][:min]].max
      else
        raise "Invalid mutation type: #{mutation_type}"
      end

    if KEY_TYPE[key] == Float
      new_hero[key] = new_hero[key].round(1)
    end

    new_hero
  end

  def breed
    husband = choose_hero
    wife = choose_hero(husband)
    new_hero = {}

    husband.each do |key, value|
      new_hero[key] = (value + wife[key]) / 2
    end

    new_hero
  end
end
