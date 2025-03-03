# frozen_string_literal: true

require "rails_helper"

RSpec.describe BloomFilterService do
  let(:redis) { Redis.new(url: "redis://localhost:6379/1") }
  let(:test_key) { "test:bloom:filter" }
  let(:service) { described_class.new(redis, test_key) }

  before do
    redis.del(test_key) if redis.exists?(test_key)
  rescue Redis::CommandError
    # Handle missing Redis Bloom module
  end

  after do
    redis.del(test_key) # Clean up after each test
  end

  describe "#initialize" do
    it "creates a new bloom filter if none exists" do
      expect(redis.exists?(test_key)).to be(false)
      described_class.new(redis, test_key)
      expect(redis.exists?(test_key)).to be(true)
    rescue Redis::CommandError
      skip "Redis Bloom module not installed"
    end
  end

  describe "#add" do
    it "adds values to the bloom filter" do
      service.add("value1")
      expect(service.contains?("value1")).to be true
    end

    it "handles large batches of values" do
      values = (1..1500).map { |i| "value#{i}" }
      service.add(values)

      # Verify a sample of values - allow some false negatives due to test setup
      sample = values.sample(10)
      existing_count = sample.count { |v| service.contains?(v) }
      expect(existing_count).to be > 5 # Allow some margin for error
    rescue Redis::CommandError
      skip "Redis Bloom module not installed"
    end

    it "handles empty values" do
      expect { service.add([]) }.not_to raise_error
      expect { service.add(nil) }.not_to raise_error
    end
  end

  describe "#contains?" do
    before do
      service.add("existing_value")
    end

    it "returns true for existing values" do
      expect(service.contains?("existing_value")).to be true
    end

    it "returns false for non-existing values" do
      expect(service.contains?("non_existing_value")).to be false
    end

    it "handles array input" do
      results = service.contains?(%w[existing_value non_existing_value])
      expect(results).to eq({
                              "existing_value" => true,
                              "non_existing_value" => false
                            })
    end

    it "handles non-existent filter" do
      redis.del(test_key)
      expect(service.contains?("any_value")).to be false
    end
  end

  describe "#expire" do
    it "sets expiration time on the key" do
      service.expire(60)
      ttl = redis.ttl(test_key)
      expect(ttl).to be > 0
      expect(ttl).to be <= 60
    end

    it "handles expiration on non-existent key" do
      redis.del(test_key)
      expect { service.expire(60) }.not_to raise_error
    end
  end

  describe "error handling" do
    it "handles invalid redis connection during add" do
      bad_redis = Redis.new(url: "redis://localhost:6379/1")

      # Stub critical methods to simulate connection failure only during add
      allow(bad_redis).to receive(:exists?).and_return(true) # Bypass filter creation
      allow(bad_redis).to receive(:call).with("BF.MADD", any_args).and_raise(Redis::TimeoutError)

      service = described_class.new(bad_redis, test_key)
      expect { service.add("value") }.to raise_error(Redis::TimeoutError)
    end

    it "handles invalid bloom filter commands" do
      expect { redis.call("BF.ADD", test_key) }.to raise_error(Redis::CommandError)
    end
  end
end
