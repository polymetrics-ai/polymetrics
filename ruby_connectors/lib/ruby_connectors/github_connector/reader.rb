# frozen_string_literal: true

require_relative "connection"

module RubyConnectors
  module GithubConnector
    class Reader
      DEFAULT_PER_PAGE = 30

      def initialize(config)
        @config = config
        @client = Connection.new(config).authorize_connection
        # TODO: uncomment after the implementation of syncs
        # @client.auto_paginate = true
      end

      def read(stream_name, page = 1, per_page = DEFAULT_PER_PAGE)
        method_name = stream_name.to_sym
        raise ArgumentError, "Unsupported stream: #{stream_name}" unless @client.respond_to?(method_name)

        result = @client.send(method_name, @config[:repository], page:, per_page:)
        {
          data: result,
          page:,
          per_page: result&.length,
          total_pages: last_page(result)
        }
      end

      private

      def last_page(result)
        return 1 unless paginated_response?(result)

        last_page_link = @client.last_response.rels[:last]
        extract_page_number(last_page_link) || 1
      end

      def paginated_response?(result)
        result.is_a?(Array) && @client.last_response
      end

      def extract_page_number(link)
        return nil unless link

        match = link.href.match(/page=(\d+)/)
        match[1].to_i if match
      end
    end
  end
end
