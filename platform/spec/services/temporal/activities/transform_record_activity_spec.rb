# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::TransformRecordActivity do
  let(:activity) { described_class.new(double("context")) }
  let(:sync) { create(:sync, destination_database_schema: schema) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:schema) do
    {
      "mapping" => [
        { "from" => "source_field", "to" => "dest_field" },
        { "from" => "name", "to" => "full_name" }
      ]
    }
  end

  describe "#execute" do
    context "when sync_run is already completed" do
      before do
        sync_run.update(extraction_completed: true)
      end

      it "returns early without processing records" do
        expect(activity).not_to receive(:transform_read_records)
        activity.execute(sync_run.id)
      end
    end

    context "when sync_run has no read records" do
      it "returns early without processing records" do
        expect(activity).not_to receive(:transform_read_records)
        activity.execute(sync_run.id)
      end
    end

    context "when sync_run has read records to process" do
      let!(:sync_read_record) do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: [
                 { "source_field" => "value1", "name" => "John Doe" },
                 { "source_field" => "value2", "name" => "Jane Smith" }
               ])
      end

      it "transforms records according to schema mapping" do
        activity.execute(sync_run.id)

        redis_key = "sync:#{sync.id}:transformed:#{sync_read_record.id}"
        transformed_data = JSON.parse(activity.send(:redis).get(redis_key))

        expect(transformed_data).to eq([
                                         { "dest_field" => "value1", "full_name" => "John Doe" },
                                         { "dest_field" => "value2", "full_name" => "Jane Smith" }
                                       ])
      end

      it "marks read record as transformed" do
        activity.execute(sync_run.id)

        sync_read_record.reload
        expect(sync_read_record.transformation_completed_at).to be_present
      end

      it "updates sync run status" do
        activity.execute(sync_run.id)

        sync_run.reload
        expect(sync_run.transformation_completed).to be true
        expect(sync_run.last_transformed_at).to be_present
      end
    end
  end

  describe "#transform_record_data" do
    let(:record) { { "source_field" => "test_value", "name" => "John Doe", "ignored_field" => "ignored" } }

    before do
      activity.instance_variable_set(:@sync, sync)
      activity.instance_variable_set(:@sync_run, sync_run)
    end

    it "transforms record according to schema mapping" do
      result = activity.send(:transform_record_data, record)

      expect(result).to eq({
                             "dest_field" => "test_value",
                             "full_name" => "John Doe"
                           })
    end

    it "excludes unmapped fields" do
      result = activity.send(:transform_record_data, record)

      expect(result).not_to include("ignored_field")
    end
  end

  describe "retry policy" do
    it "has the correct retry policy settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy[:interval]).to eq(1)
      expect(retry_policy[:backoff]).to eq(1)
      expect(retry_policy[:max_attempts]).to eq(3)
    end
  end
end
