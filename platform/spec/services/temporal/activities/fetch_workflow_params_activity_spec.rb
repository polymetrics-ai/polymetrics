# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::FetchWorkflowParamsActivity do
  let(:activity) { described_class.new(double("context")) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }

  describe "#execute" do
    let(:workflow_params) { { "key" => "value" } }
    let(:params_service) { instance_double(Etl::Extractors::WorkflowExecutionParamsService) }

    before do
      allow(Etl::Extractors::WorkflowExecutionParamsService).to receive(:new)
        .with(sync_run: sync_run)
        .and_return(params_service)
      allow(params_service).to receive(:call).and_return(workflow_params)
    end

    it "fetches workflow params for the given sync_run" do
      result = activity.execute(sync_run.id)

      expect(result).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(result[:key]).to eq("value")
    end

    it "initializes the params service with correct sync_run" do
      expect(Etl::Extractors::WorkflowExecutionParamsService).to receive(:new)
        .with(sync_run: sync_run)

      activity.execute(sync_run.id)
    end

    context "when sync_run is not found" do
      it "raises an error" do
        expect do
          activity.execute(-1)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when params service returns nil" do
      before do
        allow(params_service).to receive(:call).and_return(nil)
      end

      it "returns an empty hash with indifferent access" do
        result = activity.execute(sync_run.id)

        expect(result).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(result).to be_empty
      end
    end
  end

  describe "retry policy" do
    it "has the correct retry policy settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy[:interval]).to eq(1)
      expect(retry_policy[:backoff]).to eq(2)
      expect(retry_policy[:max_attempts]).to eq(3)
    end
  end
end
