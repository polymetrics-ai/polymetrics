# frozen_string_literal: true

class WorkflowStoreService
  WORKFLOW_KEY_PREFIX = "workflow:read_data:"
  EXPIRATION_TIME = 1.hour

  def initialize
    @redis = initialize_redis
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

    build_workflow_data(data)
  end

  private

  def workflow_key(workflow_id)
    "#{WORKFLOW_KEY_PREFIX}#{workflow_id}"
  end

  def build_workflow_data(data)
    {
      status: data["status"],
      result: parse_result(data["result"]),
      created_at: parse_timestamp(data["created_at"]),
      updated_at: parse_timestamp(data["updated_at"])
    }.with_indifferent_access
  end

  def parse_result(result)
    result ? JSON.parse(result) : nil
  end

  def parse_timestamp(timestamp)
    timestamp ? Time.zone.at(timestamp.to_i) : nil
  end
end
