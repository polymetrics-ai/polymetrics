# frozen_string_literal: true

module Activities
  class CreateSyncsActivity < ::Temporal::Activity
    def execute(connection_id)
      ActiveRecord::Base.connection_pool.with_connection do
        Syncs::CreateService.new(connection_id).call
      end
    ensure
      # This will return the connection to the pool for this specific thread
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection.active?
    end
  end
end
