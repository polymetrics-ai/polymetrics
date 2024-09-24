# frozen_string_literal: true

module RubyConnectors
  module DuckdbConnector
    class Client < Core::BaseConnector
      def initialize(config)
        super
        @connection = RubyConnectors::DuckdbConnector::Connection.new(config)
        # @reader = RubyConnectors::DuckdbConnector::Reader.new(config)
        # @writer = RubyConnectors::DuckdbConnector::Writer.new(config)
      end

      def connect
        @connection.connect
      end

      # def read(stream_name, page = 1, per_page = 30)
      #   @reader.read(stream_name, page, per_page)
      # end

      # def write(data)
      #   @writer.write(data)
      # end
    end
  end
end
