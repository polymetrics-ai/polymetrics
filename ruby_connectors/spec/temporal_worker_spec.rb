# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/temporal_worker"

RSpec.describe RubyConnectors::TemporalWorker do
  describe ".start" do
    let(:worker) { instance_double(Temporal::Worker) }
    let(:config) { double("Config") }

    before do
      allow(Temporal).to receive(:configure).and_yield(config)
      allow(config).to receive(:host=)
      allow(config).to receive(:port=)
      allow(config).to receive(:namespace=)
      allow(config).to receive(:task_queue=)
      allow(Temporal).to receive(:register_namespace)
      allow(Temporal::Worker).to receive(:new).and_return(worker)
      allow(worker).to receive(:register_workflow)
      allow(worker).to receive(:register_activity)
      allow(worker).to receive(:start)
    end

    it "configures Temporal with the correct settings" do
      described_class.start
    end

    it "registers the workflow and activity" do
      expect(worker).to receive(:register_workflow).with(RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow)
      expect(worker).to receive(:register_activity).with(RubyConnectors::Temporal::Activities::ConnectionStatusActivity)
      described_class.start
    end

    it "starts the worker" do
      expect(worker).to receive(:start)
      described_class.start
    end

    it "registers the namespace" do
      expect(Temporal).to receive(:register_namespace).with("polymetrics-dev", "Temporal Namespace for Polymetrics")
      described_class.start
    end

    context "when the namespace already exists" do
      before do
        allow(Temporal).to receive(:register_namespace).and_raise(Temporal::NamespaceAlreadyExistsFailure)
      end

      it "does not raise an error" do
        expect { described_class.start }.not_to raise_error
      end
    end
  end
end
