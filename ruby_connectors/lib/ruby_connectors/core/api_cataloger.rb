# frozen_string_literal: true

module RubyConnectors
  module Core
    class ApiCataloger
      def initialize(schemas_directory)
        @schemas_directory = schemas_directory
      end

      def catalog
        schemas = {}
        Dir.glob(File.join(@schemas_directory, '*.json')).each do |file|
          stream_name = File.basename(file, '.json')
          schemas[stream_name] = JSON.parse(File.read(file))
        end
        schemas
      end
    end
  end
end
