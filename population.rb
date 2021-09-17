require 'oj'
require_relative 'player'

class Population
  MAX_POPULATION_SIZE = 100
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
  MUTATION_RATE = 0.1 # 10% chance of one mutate
  MUTATION_TYPE = [:add, :substract, :min, :max, :average, :inverse]

  attr_reader :logger, :population

  def self.parse_seed(path)
    data = Oj.load(File.read(path), symbol_keys: true)

    data.inject({}) do |hash, hero|
      hash.merge(hero[:hero] => hero[:score])
    end
  end

  INITIAL_POPULATION = parse_seed('config/seed.json')

  def initialize(logger:, seed: INITIAL_POPULATION)
    @population = seed
    @logger = logger
  end

  def update(chosen_hero, new_score)
    return if chosen_hero.nil?

    # avoid the case when score is negative due to restart
    new_score = [new_score, 0].max
    logger.info(score: new_score)
    population[chosen_hero] = (population[chosen_hero] + new_score) / 2.0
    logger.info(chosen_hero: chosen_hero, hero_score: population[chosen_hero])

    new_hero = need_mutation? ? mutate(chosen_hero) : breed

    unless population.key?(new_hero)
      while population.count >= MAX_POPULATION_SIZE
        population.shift
      end
      population[new_hero] = 0.0
    end

    @population = population.sort_by { |_hero, score| score }.to_h
  end

  def choose_hero(existing_hero = nil)
    population.reverse_each do |hero, _score|
      next if hero == existing_hero

      chosen = [hero, nil].sample

      return chosen if chosen
    end

    return (population.keys - [existing_hero].compact).sample
  end

  private

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

      if KEY_TYPE[key] == Float
        new_hero[key] = new_hero[key].round(1)
      end
    end

    new_hero
  end

  def need_mutation?
    population.count == 1 || SecureRandom.rand < MUTATION_RATE
  end
end
