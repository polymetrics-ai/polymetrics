# frozen_string_literal: true

module RubyConnectors
  module GithubConnector
    class Cataloger
      def catalog
        RubyConnectors::Core::ApiCataloger.new(File.join(__dir__, 'schemas')).catalog
      end
    end
  end
end
