# frozen_string_literal: true

class Connection < ApplicationRecord
  include AASM

  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  has_many :syncs, dependent: :destroy
  has_many :chat_connections, dependent: :destroy
  has_many :chats, through: :chat_connections

  enum status: { created: 0, failed: 1, running: 2, paused: 3, healthy: 4 }
  enum schedule_type: { scheduled: 0, cron: 1, manual: 2 }
  enum namespace: { system_defined: 0, source_defined: 1, destination_defined: 2, user_defined: 3 }

  validates :name, presence: true, uniqueness: { scope: :workspace_id }, length: { maximum: 255 }
  validates :status, presence: true
  validates :schedule_type, presence: true
  validates :namespace, presence: true
  validates :sync_frequency, presence: true, if: :frequency_required?

  aasm column: :status, whiny_transitions: true do
    state :created, initial: true
    state :healthy, :failed, :running, :paused

    event :start do
      transitions from: %i[created healthy failed paused], to: :running
    end

    event :pause do
      transitions from: %i[running healthy], to: :paused
    end

    event :resume do
      transitions from: :paused, to: :running
    end

    event :complete do
      transitions from: :running, to: :healthy
    end

    event :fail do
      transitions from: %i[running healthy], to: :failed,
                  after: :log_failure
    end

    event :recover do
      transitions from: :failed, to: :healthy,
                  after: :log_recovery
    end
  end

  after_commit :check_health_status, if: :saved_change_to_status?

  private

  def log_failure
    Rails.logger.error("Connection #{id} failed at #{Time.current}")
  end

  def log_recovery
    Rails.logger.info("Connection #{id} recovered at #{Time.current}")
  end

  def frequency_required?
    scheduled? || cron?
  end

  def check_health_status
    return unless status_previously_changed?(to: "healthy")

    notify_chat_workflows
  end

  # TODO: This is a temporary solution to notify the chat workflows that the connection is healthy.
  # We need to find a better way to do this.
  # We need to move this to a workflow.
  def notify_chat_workflows
    chats.each do |chat|
      next if chat.status != "active"

      workflow_id = "chat_#{chat.id}"
      Temporal.signal_workflow(
        "Temporal::Workflows::Agents::DataAgent::ChatProcessingWorkflow",
        "connection_healthy",
        workflow_id,
        nil,
        { connection_id: id }
      )
    end
  end
end
