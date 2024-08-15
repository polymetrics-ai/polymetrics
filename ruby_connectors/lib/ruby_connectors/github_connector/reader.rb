# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Reader
      def initialize(config)
        @config = config
      end

      def read; end
    end
  end
end
