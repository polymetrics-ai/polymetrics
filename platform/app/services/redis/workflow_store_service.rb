# frozen_string_literal: true

module Redis
  class WorkflowStoreService
    WORKFLOW_KEY_PREFIX = "workflow:read_data:"
    EXPIRATION_TIME = 1.hour

    def initialize
      @redis = $redis
    end

    def store_workflow_data(workflow_id, data)
      key = workflow_key(workflow_id)
      @redis.multi do |multi|
        multi.hmset(key,
                    "status", "pending",
                    "data", data.to_json,
                    "created_at", Time.current.to_i)
        multi.expire(key, EXPIRATION_TIME.to_i)
      end
    end

    def update_workflow_status(workflow_id, status, result = nil)
      key = workflow_key(workflow_id)
      @redis.multi do |multi|
        multi.hmset(key,
                    "status", status,
                    "result", result&.to_json,
                    "updated_at", Time.current.to_i)
        multi.expire(key, EXPIRATION_TIME.to_i)
      end
    end

    def get_workflow_data(workflow_id)
      key = workflow_key(workflow_id)
      data = @redis.hgetall(key)
      return nil if data.empty?

      {
        status: data["status"],
        result: data["result"] ? JSON.parse(data["result"]) : nil,
        created_at: Time.zone.at(data["created_at"].to_i),
        updated_at: data["updated_at"] ? Time.zone.at(data["updated_at"].to_i) : nil
      }.with_indifferent_access
    end

    private

    def workflow_key(workflow_id)
      "#{WORKFLOW_KEY_PREFIX}#{workflow_id}"
    end
  end
end
