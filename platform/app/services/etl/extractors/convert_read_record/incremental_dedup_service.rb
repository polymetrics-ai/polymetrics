# frozen_string_literal: true

module Etl
  module Extractors
    module ConvertReadRecord
      class IncrementalDedupService
        REDIS_KEY_TTL = 7.days.to_i # Keep sync run data for 7 days

        def initialize(sync_run, sync_read_record_id, sync_read_record_data)
          @sync_run = sync_run
          @sync = sync_run.sync
          @sync_read_record_id = sync_read_record_id
          @sync_read_record_data = sync_read_record_data
          @existing_signatures = {}
        end

        def call
          return unless @sync_read_record_data.is_a?(Array)
          
          load_existing_signatures
          
          @sync_read_record_data.each do |record_data|
            process_record(record_data)
            store_pk_signature_in_redis(record_data)
          end
        end

        private

        def load_existing_signatures
          existing_records = SyncWriteRecord
            .where(sync_id: @sync.id)
            .pluck(:primary_key_signature, :data_signature)
            
          existing_records.each do |pk_sig, data_sig|
            @existing_signatures[pk_sig] = data_sig if pk_sig
          end
        end

        def process_record(record_data)
          pk_signature = generate_primary_key_signature(record_data)
          return unless pk_signature

          data_signature = generate_data_signature(record_data)
          
          # Skip if both signatures match (exact duplicate)
          return if @existing_signatures[pk_signature] == data_signature

          create_write_record(record_data, pk_signature, data_signature)
        end

        def store_pk_signature_in_redis(record_data)
          pk_signature = generate_primary_key_signature(record_data)
          return unless pk_signature

          redis.sadd(current_sync_run_key, pk_signature)
          redis.expire(current_sync_run_key, REDIS_KEY_TTL)
        end

        def create_write_record(record_data, pk_signature, data_signature)
          SyncWriteRecord.create!(
            sync: @sync,
            sync_run: @sync_run,
            sync_read_record_id: @sync_read_record_id,
            data: record_data,
            primary_key_signature: pk_signature,
            data_signature: data_signature,
            destination_action: determine_destination_action
          )
        end

        def generate_primary_key_signature(record_data)
          return nil unless @sync.source_defined_primary_key.present?

          # Ensure record_data is a hash
          record_hash = record_data.is_a?(Hash) ? record_data : record_data.to_h
          
          primary_key_values = @sync.source_defined_primary_key.map do |key| 
            record_hash[key.to_s] || record_hash[key.to_sym]
          end
          
          return nil if primary_key_values.any?(&:nil?)

          key_string = "#{primary_key_values.sort.join('-')}-#{@sync.id}"
          Digest::SHA256.hexdigest(key_string)
        end

        def generate_data_signature(record_data)
          normalized_data = case record_data
                          when Hash
                            record_data.deep_sort.to_json
                          when Array
                            record_data.deep_sort_by(&:to_s).to_json
                          else
                            record_data.to_json
                          end

          Digest::SHA256.hexdigest("#{normalized_data}-#{@sync.id}")
        end

        def determine_destination_action
          case @sync.connection.destination.integration_type
          when 'database'
            :insert
          else
            :create
          end
        end

        def redis
          @redis ||= initialize_redis
        end

        def current_sync_run_key
          "sync:#{@sync.id}:run:#{@sync_run.id}:pk_signatures"
        end
      end
    end
  end
end 