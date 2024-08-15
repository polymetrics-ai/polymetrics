# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Client < Core::BaseConnector
      def initialize(config)
        super
        @connection = RubyConnectors::GithubConnector::Connection.new(config)
        @reader = RubyConnectors::GithubConnector::Reader.new(config)
        @writer = RubyConnectors::GithubConnector::Writer.new(config)
      end

      def connect
        @connection.connect
      end

      # def read
      #   @reader.read
      # end

      # def write(data)
      #   @writer.write(data)
      # end
    end
  end
end
