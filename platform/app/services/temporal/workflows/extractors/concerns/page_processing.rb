# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      module PageProcessingConcern
        extend ActiveSupport::Concern

        private

        def handle_first_page(signal_data)
          return if @total_pages.present?
          return if @processed_pages.include?(1)

          process_first_page(signal_data)
          request_next_page if @total_pages > 1
        end

        def process_first_page(signal_data)
          Activities::ProcessFirstPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data
          )

          @total_pages = signal_data[:total_pages]
          @processed_pages.add(1)
        end

        def handle_page_completion(signal_data)
          page_number = signal_data[:page_number]
          return unless should_process_page?(signal_data)

          process_page(signal_data, page_number)
          request_next_page if @total_pages > page_number
        end

        def process_page(signal_data, page_number)
          Activities::ProcessPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data,
            page_number: page_number
          )

          @processed_pages.add(page_number)
        end

        def should_process_page?(signal_data)
          page_number = signal_data[:page_number]

          return false if @total_pages.blank?
          return false if @processed_pages.include?(page_number)
          return false if page_number > @total_pages

          true
        end

        def pages_processed?
          return false if @processed_pages.empty?

          expected_pages = (1..@total_pages).to_set
          @processed_pages == expected_pages
        end
      end
    end
  end
end
