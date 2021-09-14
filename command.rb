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
