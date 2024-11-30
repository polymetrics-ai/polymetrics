# frozen_string_literal: true

require_relative "connection"

module RubyConnectors
  module GithubConnector
    class Reader
      DEFAULT_PER_PAGE = 30

      def initialize(config)
        @config = config.deep_symbolize_keys
        @client = Connection.new(config).authorize_connection

        @client.auto_paginate = true
      end

      def read(stream_name, page = 1, per_page = DEFAULT_PER_PAGE)
        method_name = stream_name.to_sym
        raise ArgumentError, "Unsupported stream: #{stream_name}" unless @client.respond_to?(method_name)

        result = @client.send(method_name, @config[:repository], page: page, per_page: per_page)

        {
          data: sawyer_to_hash(result),
          page: page,
          per_page: per_page,
          total_pages: last_page(result)
        }
      end

      private

      def last_page(result)
        return 1 if @client.auto_paginate
        return 1 unless paginated_response?(result)

        if @client.last_response.rels[:last]
          extract_page_number(@client.last_response.rels[:last])
        elsif @client.last_response.rels[:prev]
          # If we're on the last page, use prev link to determine total
          extract_page_number(@client.last_response.rels[:prev]) + 1
        else
          # If there's only one page
          1
        end
      end

      def paginated_response?(result)
        result.is_a?(Array) && @client.last_response
      end

      def extract_page_number(link)
        return nil unless link

        match = link.href.match(/page=(\d+)/)
        match[1].to_i if match
      end

      def sawyer_to_hash(resource)
        case resource
        when Sawyer::Resource
          result = {}
          resource.to_hash.each do |key, value|
            result[key] = sawyer_to_hash(value)
          end
          result
        when Array
          resource.map { |item| sawyer_to_hash(item) }
        else
          resource
        end
      end
    end
  end
end
