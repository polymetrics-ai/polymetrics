# frozen_string_literal: true

module RubyConnectors
  module Core
    class BaseConnector
      def initialize(config)
        @config = config
      end

      def connect
        raise NotImplementedError, "#{self.class} must implement #connect"
      end

      def read
        raise NotImplementedError, "#{self.class} must implement #read"
      end

      def write(data)
        raise NotImplementedError, "#{self.class} must implement #write"
      end
    end
  end
end
