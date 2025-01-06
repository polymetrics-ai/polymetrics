# frozen_string_literal: true

module Etl
  # Represents the result of an operation with success/failure status
  class Result
    attr_reader :payload, :error

    def self.success(payload)
      new(payload: payload)
    end

    def self.failure(error)
      new(error: error)
    end

    def success?
      error.nil?
    end

    def failure?
      !success?
    end

    private

    def initialize(payload: nil, error: nil)
      @payload = payload
      @error = error
    end
  end
end
