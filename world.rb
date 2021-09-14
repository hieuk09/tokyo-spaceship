class World
  ID = 'id'
  TEAM = 'teamnames'
  STATE = 'state'

  attr_accessor :current_player_id, :event
  attr_reader :commands

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
  end

  def bullets_colliding(within: 1)
    @bullets.select do |bullet|
      bullet.colliding?(current_player, within: within)
    end
  end

  def players_colliding(within: 1)
    @players.map do |_id, player|
      if player.id != current_player_id
        [player, player.colliding(current_player, within: within)]
      else
        [player, nil]
      end
    end.select { |player, time| !!time }
  end

  def current_player
    @players[current_player_id]
  end

  def nearest_player
    nearest_player = nil
    min_distance = 1_000_000

    @players.find do |_id, player|
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
end
