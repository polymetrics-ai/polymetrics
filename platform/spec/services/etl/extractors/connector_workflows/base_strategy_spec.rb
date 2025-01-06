# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConnectorWorkflows::BaseStrategy do
  let(:strategy) { described_class.new }
  let(:sync_run) { create(:sync_run) }

  describe "#workflow_class" do
    it "raises NotImplementedError" do
      expect { strategy.workflow_class }.to raise_error(NotImplementedError)
    end
  end

  describe "#build_params" do
    let(:source) { sync_run.sync.connection.source }

    it "returns base parameters" do
      expected_params = {
        "connector_class_name" => source.connector_class_name,
        "configuration" => source.configuration,
        "stream_name" => sync_run.sync.stream_name
      }

      expect(strategy.build_params(sync_run: sync_run)).to eq(expected_params)
    end
  end

  describe "#workflow_options" do
    context "when language is ruby" do
      let(:source) { create(:connector, connector_language: :ruby) }
      let(:sync_run) { create(:sync_run, sync: create(:sync, connection: create(:connection, source: source))) }

      it "returns ruby queue" do
        expect(strategy.workflow_options(sync_run)).to eq(task_queue: "ruby_connectors_queue")
      end
    end

    context "when language is python" do
      let(:source) { create(:connector, connector_language: :python) }
      let(:sync_run) { create(:sync_run, sync: create(:sync, connection: create(:connection, source: source))) }

      it "returns python queue" do
        expect(strategy.workflow_options(sync_run)).to eq(task_queue: "python_connectors_queue")
      end
    end

    context "when language is javascript" do
      let(:source) { create(:connector, connector_language: :javascript) }
      let(:sync_run) { create(:sync_run, sync: create(:sync, connection: create(:connection, source: source))) }

      it "returns javascript queue" do
        expect(strategy.workflow_options(sync_run)).to eq(task_queue: "javascript_connectors_queue")
      end
    end

    context "when language is nil" do
      let(:source) { create(:connector) }
      let(:sync_run) { create(:sync_run, sync: create(:sync, connection: create(:connection, source: source))) }

      before { source.update_column(:connector_language, nil) }

      it "returns ruby queue as default" do
        expect(strategy.workflow_options(sync_run)).to eq(task_queue: "ruby_connectors_queue")
      end
    end
  end
end
