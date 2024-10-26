# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Client < Core::BaseConnector
      def initialize(config = nil)
        super
      end

      def connect
        connection = RubyConnectors::GithubConnector::Connection.new(@config)
        connection.connect
      end

      def read(stream_name, page = 1, per_page = 30)
        reader = RubyConnectors::GithubConnector::Reader.new(@config)
        reader.read(stream_name, page, per_page)
      end

      def catalog
        cataloger = RubyConnectors::GithubConnector::Cataloger.new
        cataloger.catalog
      end

      # def write(data)
      #   writer = RubyConnectors::GithubConnector::Writer.new(@config)
      #   writer.write(data)
      # end
    end
  end
end
