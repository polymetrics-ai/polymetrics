# frozen_string_literal: true

class BloomFilterService
  def initialize(redis, key, capacity = 1_000_000, error_rate = 0.001)
    @redis = redis || initialize_redis
    @key = key
    @capacity = capacity
    @error_rate = error_rate
    ensure_filter_exists
  end

  def add(values)
    return if Array(values).empty?

    Array(values).each_slice(1000) do |batch|
      @redis.call("BF.MADD", @key, *batch)
    end
  end

  def contains?(values)
    return {} if Array(values).empty?

    results = @redis.call("BF.MEXISTS", @key, *Array(values))

    if values.is_a?(Array)
      values.zip(results.map { |r| r == 1 }).to_h
    else
      results[0] == 1
    end
  end

  def expire(ttl)
    @redis.expire(@key, ttl)
  end

  private

  def ensure_filter_exists
    # Check if the filter exists
    return if @redis.exists?(@key)

    # Create the filter if it doesn't exist
    @redis.call("BF.RESERVE", @key, @error_rate, @capacity)
  end
end
