require 'rubygems'
require 'bundler/setup'
require 'websocket-eventmachine-client'
require 'oj'
require 'securerandom'

require_relative 'command'
require_relative 'game'
require_relative 'player'
require_relative 'bullet'
require_relative 'size'
require_relative 'point'
require_relative 'velocity'
require_relative 'world'

URL = 'ws://localhost:8091/socket?key=hieuk091234&name=hieuk09'

EM.run do
  ws = WebSocket::EventMachine::Client.connect(uri: URL)

  ws.onopen do
    puts "Connected"
  end

  ws.onmessage do |data, type|
    data = Oj.load(data)
    @world = Game.update(@world, data)
    action = Game.decide(@world)
    ws.send(Oj.dump(action.data))
  end

  ws.onclose do |code, reason|
    puts "Disconnected with status code: #{code}"
  end

  EventMachine.next_tick do
  end
end
