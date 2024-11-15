module RubyConnectors
  module Services
    module Redis
      class WorkflowStoreService
        WORKFLOW_KEY_PREFIX = "workflow:read_data:"
        EXPIRATION_TIME = 3600 # 1 hour in seconds

        def initialize
          @redis = ::Redis.new(
            url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
          )
        end

        def store_workflow_data(workflow_id, result)
          key = workflow_key(workflow_id)
          @redis.multi do |multi|
            multi.hmset(key, 
              'status', 'pending',
              'result', result.to_json,
              'created_at', Time.current.to_i
            )
            multi.expire(key, EXPIRATION_TIME)
          end
        end

        def update_workflow_status(workflow_id, status, result = nil)
          key = workflow_key(workflow_id)
          @redis.multi do |multi|
            multi.hmset(key, 
              'status', status,
              'result', result&.to_json,
              'updated_at', Time.current.to_i
            )
            multi.expire(key, EXPIRATION_TIME)
          end
        end

        def get_workflow_data(workflow_id)
          key = workflow_key(workflow_id)
          data = @redis.hgetall(key)
          return nil if data.empty?

          {
            status: data['status'],
            result: data['result'] ? JSON.parse(data['result']) : nil,
            created_at: Time.at(data['created_at'].to_i),
            updated_at: data['updated_at'] ? Time.at(data['updated_at'].to_i) : nil
          }.with_indifferent_access
        end

        private

        def workflow_key(workflow_id)
          "#{WORKFLOW_KEY_PREFIX}#{workflow_id}"
        end
      end
    end
  end
end 