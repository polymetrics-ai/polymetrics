# frozen_string_literal: true

module Etl
  module Extractors
    module ConvertReadRecord
      class ProcessDeletionsService
        REDIS_KEY_TTL = 7.days.to_i # Keep sync run data for 7 days

        def initialize(sync_run, sync_read_record_id, sync_read_record_data)
          @sync_run = sync_run
          @sync = sync_run.sync
          @sync_read_record_id = sync_read_record_id
          @sync_read_record_data = sync_read_record_data
        end

        def call
          return unless previous_sync_run_id
          return if @sync.source_defined_primary_key.blank?

          deleted_signatures = find_deleted_signatures
          return if deleted_signatures&.empty?

          create_delete_records(deleted_signatures)
        end

        private

        def find_deleted_signatures
          # Find signatures present in previous run but missing in current run
          deleted_signatures = redis.sdiff(previous_sync_run_key, current_sync_run_key)
          return [] if deleted_signatures.empty?

          # Exclude records that were already processed as deletions or creates in this sync run
          existing_processed_signatures = SyncWriteRecord
                                          .where(sync_run_id: @sync_run.id)
                                          .where(destination_action: %i[delete create insert])
                                          .pluck(:primary_key_signature)

          deleted_signatures - existing_processed_signatures
        end

        def create_delete_records(signatures)
          # Fetch the last known state of these records
          last_known_records = SyncWriteRecord
                               .where(sync_id: @sync.id, primary_key_signature: signatures)
                               .where.not(destination_action: :delete)
                               .order(created_at: :desc)

          last_known_records.each do |record|
            SyncWriteRecord.create!(
              sync: @sync,
              sync_run: @sync_run,
              sync_read_record_id: @sync_read_record_id,
              data: record.data, # Use the last known data for the record
              primary_key_signature: record.primary_key_signature,
              data_signature: record.data_signature,
              destination_action: :delete
            )
          end
        end

        def redis
          @redis ||= initialize_redis
        end

        def current_sync_run_key
          "sync:#{@sync.id}:run:#{@sync_run.id}:pk_signatures"
        end

        def previous_sync_run_key
          return nil unless previous_sync_run_id

          "sync:#{@sync.id}:run:#{previous_sync_run_id}:pk_signatures"
        end

        def previous_sync_run_id
          @previous_sync_run_id ||= SyncRun
                                    .where(sync_id: @sync.id, extraction_completed: true)
                                    .where(id: ...@sync_run.id)
                                    .order(id: :desc)
                                    .limit(1)
                                    .pick(:id)
        end
      end
    end
  end
end
