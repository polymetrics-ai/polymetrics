# frozen_string_literal: true

module Activities
  class CreateConnectionActivity < ::Temporal::Activity
    def execute(connector_id)
      Connections::CreateService.call(connector_id)
    end
  end
end
