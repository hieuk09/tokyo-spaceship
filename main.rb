require 'rubygems'
require 'bundler/setup'
require 'websocket-eventmachine-client'
require 'oj'
require 'securerandom'
require 'logger'

require_relative 'command'
require_relative 'game'
require_relative 'player'
require_relative 'bullet'
require_relative 'size'
require_relative 'point'
require_relative 'velocity'
require_relative 'world'

URL = 'ws://localhost:8091/socket?key=hieuk091234&name=hieuk09'
#URL = 'ws://tokyo.thuc.space/socket?key=ruby-12345&name=ruby_1'

EM.run do
  ws = WebSocket::EventMachine::Client.connect(uri: URL)
  logger = Logger.new('development.log')
  game = Game.new(logger: logger)

  ws.onopen do
    puts "Connected"
  end

  ws.onmessage do |data, type|
    data = Oj.load(data)
    logger.info(data)
    @world = game.update(@world, data)
    action = game.decide(@world)
    logger.info(action.data)
    ws.send(Oj.dump(action.data))
  end

  ws.onclose do |code, reason|
    puts "Disconnected with status code: #{code}"
  end
end
