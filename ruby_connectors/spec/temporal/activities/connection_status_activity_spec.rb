# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/temporal/activities/connection_status_activity"

RSpec.describe RubyConnectors::Temporal::Activities::ConnectionStatusActivity do
  let(:connector) { { personal_access_token: "token", repository: "rails/rails" } }
  let(:activity) { described_class.new(connector) } # Pass the connector here

  describe "#execute" do
    it "calls the ConnectorService to fetch connection status" do
      expect(RubyConnectors::Services::ConnectorService)
        .to receive(:connect_and_fetch_status).with(connector)

      activity.execute(connector)
    end
  end
end
