class Command
  def next; end

  def data
    raise NotImlemented
  end
end

class Run < Command
  def initialize(throttle:)
    @throttle = throttle
  end

  def data
    { "e" => "throttle", "data" => @throttle }
  end
end

class Rotate < Command
  def initialize(angle:)
    @angle = angle
  end

  def data
    { "e" => "rotate", "data" => @angle }
  end
end

class Shoot < Command
  def data
    { "e" => "fire" }
  end
end

class Noop < Command
  def data
    { "e" => "rotate", "data" => 0 }
  end
end

class Dodge < Command
  RUN_DURATION = 2

  def initialize(world, bullets)
    @current_player = world.current_player
    @bullets = bullets
  end

  def data
    angle = @current_player.dodge(@bullets)
    Rotate.new(angle: angle).data
  end

  def next
    [Run.new(throttle: 1)] * RUN_DURATION
  end
end
