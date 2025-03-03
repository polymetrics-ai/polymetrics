# frozen_string_literal: true

module Etl
  module Extractors
    module ConvertReadRecord
      class ProcessDeletionsService
        REDIS_KEY_TTL = 7.days.to_i # Keep sync run data for 7 days
        BATCH_SIZE = 1000 # Process records in batches

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
          # Use a more efficient query by batching
          exclude_already_processed_signatures(deleted_signatures)
        end

        def exclude_already_processed_signatures(signatures)
          result = signatures.dup

          signatures.each_slice(BATCH_SIZE) do |batch|
            existing = SyncWriteRecord
                       .where(sync_run_id: @sync_run.id)
                       .where(destination_action: %i[delete create insert])
                       .where(primary_key_signature: batch)
                       .pluck(:primary_key_signature)

            result -= existing if existing.any?
          end

          result
        end

        def create_delete_records(deleted_signatures)
          deleted_signatures.each_slice(BATCH_SIZE) do |batch_signatures|
            # Find records to delete in the database
            records_to_delete = find_records_to_delete(batch_signatures)

            # Skip if nothing to delete
            next if records_to_delete.empty?

            # Create delete records in bulk
            create_delete_records_batch(records_to_delete)
          end
        end

        def find_records_to_delete(signatures)
          # Find the latest versions of records with these signatures
          SyncWriteRecord
            .where(sync_id: @sync.id, primary_key_signature: signatures)
            .order(primary_key_signature: :asc, created_at: :desc)
            .select("DISTINCT ON (primary_key_signature) *")
        end

        # rubocop:disable Metrics/MethodLength
        def create_delete_records_batch(records)
          attributes = records.map do |record|
            record_with_system_fields = record.data.deep_dup
            record_with_system_fields["_polymetrics_id"] = record.data_signature

            {
              sync_id: @sync.id,
              sync_run_id: @sync_run.id,
              sync_read_record_id: @sync_read_record_id,
              data: record_with_system_fields,
              primary_key_signature: record.primary_key_signature,
              data_signature: record.data_signature,
              destination_action: :delete,
              created_at: Time.current,
              updated_at: Time.current
            }
          end

          SyncWriteRecord.insert_all!(attributes)
        end
        # rubocop:enable Metrics/MethodLength

        def previous_sync_run_id
          @previous_sync_run_id ||= @sync.sync_runs
                                         .where.not(id: @sync_run.id)
                                         .where(extraction_completed: true)
                                         .order(created_at: :desc)
                                         .limit(1)
                                         .pick(:id)
        end

        def previous_sync_run_key
          "sync:#{@sync.id}:run:#{previous_sync_run_id}:signatures"
        end

        def current_sync_run_key
          "sync:#{@sync.id}:run:#{@sync_run.id}:signatures"
        end

        def redis
          @redis ||= initialize_redis
        end
      end
    end
  end
end
