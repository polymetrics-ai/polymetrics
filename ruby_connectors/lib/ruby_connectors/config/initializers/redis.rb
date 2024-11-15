require 'redis'

module RubyConnectors
  class << self
    def redis
      @redis ||= Redis.new(
        url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
      )
    end
  end
end 