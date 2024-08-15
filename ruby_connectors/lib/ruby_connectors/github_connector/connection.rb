# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Connection
      def initialize(config)
        @config = config.with_indifferent_access
      end

      def connect
        client = authorize_connection
        client.repository?(@config[:repository])
      end

      private

      def authorize_connection
        Octokit::Client.new(access_token: @config[:personal_access_token])
      end
    end
  end
end
