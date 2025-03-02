# frozen_string_literal: true

module Etl
  module Extractors
    module ConvertReadRecord
      # rubocop:disable Metrics/ClassLength
      class IncrementalDedupService
        REDIS_KEY_TTL = 7.days.to_i
        BATCH_SIZE = 1000

        def initialize(sync_run, activity)
          @sync_run = sync_run
          @sync = sync_run.sync
          @redis_key = "sync:#{@sync.id}:run:#{@sync_run.id}:transformed"
          @bloom_filter = initialize_bloom_filter
          @failed_records = []
          @activity = activity
        end

        def call
          return { success: false, error: "No records found to process" } if @sync_run.sync_read_records.empty?

          process_all_records
          process_deletions
          mark_transformation_completed

          generate_result
        end

        private

        def process_all_records
          # Fetch all transformed data from Redis hash
          all_transformed_data = fetch_all_transformed_data
          return if all_transformed_data.empty?

          # Process each record's data
          all_transformed_data.each do |record_id, record_data|
            @activity.heartbeat
            process_records_in_batches(record_data, record_id)
            mark_record_as_processed(record_id)
          rescue StandardError => e
            @failed_records << { id: record_id, error: e.message }
            Rails.logger.error("Failed to process record #{record_id}: #{e.message}")
          end
        end

        def mark_record_as_processed(record_id)
          SyncReadRecord.where(id: record_id).update_all(transformation_completed_at: Time.current)
        end

        def initialize_bloom_filter
          key = "sync:#{@sync.id}:signatures:bloom"
          BloomFilterService.new(redis, key)
        end

        def process_records_in_batches(records, record_id)
          records.each_slice(BATCH_SIZE) do |batch|
            processed_batch = prepare_batch(batch)
            next if processed_batch.empty?

            new_records = filter_duplicates(processed_batch)
            bulk_create_records(new_records, record_id) if new_records.any?
            store_pk_signatures(processed_batch.pluck(:pk_signature))
          end
        end

        def prepare_batch(batch)
          batch.filter_map do |record|
            pk_sig = generate_primary_key_signature(record)
            next unless pk_sig

            data_sig = generate_data_signature(record)
            {
              record: record,
              pk_signature: pk_sig,
              data_signature: data_sig,
              combined_signature: "#{pk_sig}:#{data_sig}"
            }
          end
        end

        # rubocop:disable Metrics/MethodLength
        def filter_duplicates(processed_batch)
          combined_signatures = processed_batch.pluck(:combined_signature)

          potential_exists = @bloom_filter.contains?(combined_signatures)

          definite_new = []
          potential_duplicates = []

          processed_batch.each do |record_data|
            sig = record_data[:combined_signature]
            if potential_exists[sig]
              potential_duplicates << record_data
            else
              definite_new << record_data
            end
          end

          @bloom_filter.add(definite_new.pluck(:combined_signature))
          @bloom_filter.expire(REDIS_KEY_TTL)

          verified_new = verify_with_database(potential_duplicates)

          definite_new + verified_new
        end
        # rubocop:enable Metrics/MethodLength

        def verify_with_database(potential_duplicates)
          return [] if potential_duplicates.empty?

          by_pk_signature = potential_duplicates.group_by { |r| r[:pk_signature] }
          pk_signatures = by_pk_signature.keys

          existing_records = SyncWriteRecord
                             .where(sync_id: @sync.id, primary_key_signature: pk_signatures)
                             .pluck(:primary_key_signature, :data_signature)

          existing_combinations = existing_records.to_set { |pk, data| "#{pk}:#{data}" }

          non_duplicates = potential_duplicates.reject do |record_data|
            existing_combinations.include?(record_data[:combined_signature])
          end

          @bloom_filter.add(non_duplicates.pluck(:combined_signature))

          non_duplicates
        end

        # rubocop:disable Metrics/MethodLength
        def bulk_create_records(records, sync_read_record_id)
          attributes = records.map do |record_data|
            record_with_system_fields = record_data[:record].deep_dup
            record_with_system_fields["_polymetrics_id"] = record_data[:data_signature]
            record_with_system_fields["_polymetrics_extracted_at"] = Time.current.iso8601

            {
              sync_id: @sync.id,
              sync_run_id: @sync_run.id,
              sync_read_record_id: sync_read_record_id,
              data: record_with_system_fields,
              primary_key_signature: record_data[:pk_signature],
              data_signature: record_data[:data_signature],
              destination_action: determine_destination_action,
              created_at: Time.current,
              updated_at: Time.current
            }
          end

          SyncWriteRecord.insert_all!(attributes)
        end
        # rubocop:enable Metrics/MethodLength

        def process_deletions
          Etl::Extractors::ConvertReadRecord::ProcessDeletionsService.new(
            @sync_run,
            @sync_run.sync_read_records.last&.id,
            @sync_run.sync_read_records.last&.data
          ).call
        end

        def mark_transformation_completed
          transformation_completed = @sync_run.sync_read_records.all? { |record| record.transformation_completed_at.present? }

          @sync_run.update!(
            transformation_completed: transformation_completed,
            last_transformed_at: Time.current
          )
        end

        def generate_result
          total_records = @sync_run.total_records_read

          if @failed_records.size == total_records
            {
              success: false,
              error: "All #{total_records} records failed to convert",
              failed_records: @failed_records
            }
          else
            {
              success: true,
              transformation_completed: @sync_run.transformation_completed,
              warning: @failed_records.any? ? "#{@failed_records.size} out of #{total_records} records failed to convert" : nil,
              failed_records: @failed_records.any? ? @failed_records : nil
            }.compact
          end
        end

        def store_pk_signatures(signatures)
          redis.sadd(current_sync_run_key, signatures)
          redis.expire(current_sync_run_key, REDIS_KEY_TTL)
        end

        # Updated to fetch from the Redis hash for a specific record
        def fetch_record_data(record_id)
          data_json = redis.hget(@redis_key, record_id.to_s)
          return [] unless data_json

          JSON.parse(data_json)
        rescue JSON::ParserError
          []
        end

        # New method to fetch all transformed data at once
        def fetch_all_transformed_data
          transformed_data = {}

          redis.hgetall(@redis_key).each do |record_id, data_json|
            transformed_data[record_id.to_i] = JSON.parse(data_json)
          rescue JSON::ParserError
            @failed_records << { id: record_id.to_i, error: "Invalid JSON data" }
          end

          transformed_data
        end

        def redis
          @redis ||= initialize_redis
        end

        def current_sync_run_key
          "sync:#{@sync.id}:run:#{@sync_run.id}:signatures"
        end

        def generate_primary_key_signature(record_data)
          return nil if @sync.source_defined_primary_key.blank?

          record_hash = record_data.is_a?(Hash) ? record_data : record_data.to_h

          primary_key_values = @sync.source_defined_primary_key.map do |key|
            record_hash[key.to_s] || record_hash[key.to_sym]
          end

          return nil if primary_key_values.any?(&:nil?)

          key_string = "#{primary_key_values.sort.join("-")}-#{@sync.id}"
          Digest::SHA256.hexdigest(key_string)
        end

        def generate_data_signature(record_data)
          record_hash = record_data.is_a?(Hash) ? record_data : record_data.to_h

          Digest::SHA256.hexdigest(record_hash.sort.to_h.to_json)
        end

        def determine_destination_action
          @sync.connection.destination.integration_type == "database" ? :insert : :create
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
