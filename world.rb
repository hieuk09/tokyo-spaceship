# frozen_string_literal: true

class World
  ID = 'id'
  TEAM = 'teamnames'
  STATE = 'state'

  attr_accessor :current_player_id, :event
  attr_reader :commands, :bullets

  def initialize
    @commands = []
  end

  def players=(players)
    @players = players.each_with_object({}) do |(id, player_name), hash|
      hash[id.to_i] = Player.new({ 'id' => id.to_i, 'name' => player_name })
    end
  end

  def preparing?
    event != STATE
  end

  def dead?
    current_player.nil?
  end

  def update_state(data)
    @size = Size.new(*data['bounds'])
    @players = parse_players(data['players'])
    @bullets = parse_bullets(data['bullets'])
    @current_score = calculate_score(data['scoreboard'])
  end

  def bullets_colliding(within: 1)
    @bullets.select do |bullet|
      bullet.colliding?(current_player, within: within)
    end
  end

  def players_colliding(within: 1)
    @players.map { |_id, player| player }
      .select do |player|
        player.id != current_player_id && player.colliding?(current_player, within: within)
      end
  end

  def nearest_entity(entities)
    near_entity = entities.first
    min_distance = current_player.distance(near_entity)

    entities.each do |entity|
      distance = current_player.distance(entity)
      if distance < min_distance
        min_distance = distance
        near_entity = entity
      end
    end

    near_entity
  end

  def nearby_players(within:)
    @players.values.select do |player|
      player.id != current_player_id &&
        player.distance(current_player) <= within
    end
  end

  def current_player
    @players[current_player_id]
  end

  def current_score
    @current_score || 0
  end

  def nearest_player(other_players = @players.values)
    nearest_player = nil
    min_distance = 1_000_000

    other_players.each do |player|
      if player.id != current_player_id
        distance = player.distance(current_player)

        if distance < min_distance
          min_distance = distance
          nearest_player = player
        end
      end
    end

    nearest_player
  end

  private

  def parse_players(players)
    players.each_with_object({}) do |player, hash|
      hash[player['id']] = Player.new(player)
    end
  end

  def parse_bullets(bullets)
    bullets.map do |bullet|
      Bullet.new(bullet)
    end
  end

  def calculate_score(scoreboard)
    # sort score by ascending order
    current_user_score = scoreboard[current_player_id.to_s]
    return 0 if current_user_score.nil?

    scoreboard = scoreboard.sort_by { |_player_id, score| score }
    above_competitor_score = nil
    below_competitor_score = nil

    scoreboard.each do |player_id, score|
      if score <= current_user_score
        below_competitor_score = score
      end

      if above_competitor_score.nil? && current_player_id.to_s != player_id &&
          score >= current_user_score

        above_competitor_score = score
      end
    end

    if above_competitor_score
      current_user_score - above_competitor_score
    elsif below_competitor_score
      current_user_score - below_competitor_score
    else
      0
    end
  end
end
