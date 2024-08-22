# frozen_string_literal: true

namespace :temporal do
  desc "Start Temporal worker"
  task start_worker: :environment do
    TemporalWorker.start
  end
end
