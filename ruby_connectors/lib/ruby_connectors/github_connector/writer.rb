# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Writer
      def initialize(config)
        @config = config
      end

      def write; end
    end
  end
end
