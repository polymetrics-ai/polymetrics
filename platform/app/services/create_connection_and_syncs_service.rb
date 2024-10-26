# frozen_string_literal: true


  class CreateConnectionAndSyncsService
    def initialize(connector_id)
      @connector_id = connector_id
    end

    def call
      ActiveRecord::Base.transaction do
        create_connection
        create_syncs
      end
    end

    private

    def create_connection
      @connection_id = Connections::CreateService.new(@connector_id).call
    end

    def create_syncs
      Syncs::CreateService.new(@connection_id).call
    end
  end