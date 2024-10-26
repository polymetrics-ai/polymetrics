# convert this tests to integration tests and use vcr

# # frozen_string_literal: true

# require "spec_helper"
# require "ruby_connectors/temporal/workflows/connection_status_workflow"

# RSpec.describe RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow do
#   let(:connector) do
#     { configuration: { personal_access_token: "token", repository: "rails/rails" }, connector_type: "github" }
#   end
#   let(:workflow) { described_class.new(connector) }

#   describe "#execute" do
#     it "executes the workflow and calls the activity" do
#       expect(RubyConnectors::Temporal::Activities::ConnectionStatusActivity)
#         .to receive(:execute!).with(connector)

#       workflow.execute(connector)
#     end
#   end
# end

