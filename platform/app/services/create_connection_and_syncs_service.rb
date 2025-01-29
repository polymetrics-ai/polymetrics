# frozen_string_literal: true

class CreateConnectionAndSyncsService
  def initialize(connector_id, streams = nil)
    @connector_id = connector_id
    @streams = streams
  end

  def call
    ActiveRecord::Base.transaction do
      create_connection
      create_syncs
    end

    @connection_id
  end

  private

  def create_connection
    @connection_id = Connections::CreateService.new(@connector_id, @streams).call
  end

  def create_syncs
    # Create syncs for specified streams or all available streams
    Syncs::CreateService.new(@connection_id, @streams).call
  end
end
