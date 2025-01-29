# frozen_string_literal: true

module Ai
  module ResponseSchemas
    class SchemaManager
      class << self
        def fetch(schema_name)
          fetch_schema(schema_name)
        end

        def method_missing(method_name, *args)
          if schema_exists?(method_name)
            fetch_schema(method_name)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          schema_exists?(method_name) || super
        end

        private

        def schema_exists?(name)
          File.exist?(schema_path(name))
        end

        def fetch_schema(name)
          schema_cache[name] ||= begin
            file_path = schema_path(name)
            raise SchemaNotFoundError, "Schema '#{name}' not found at #{file_path}" unless File.exist?(file_path)

            JSON.parse(File.read(file_path))
          end
        end

        def schema_cache
          @schema_cache ||= {}
        end

        def schema_path(name)
          Rails.root.join("app", "services", "ai", "response_schemas", "#{name}.json")
        end
      end
    end

    class SchemaNotFoundError < StandardError; end
  end
end
