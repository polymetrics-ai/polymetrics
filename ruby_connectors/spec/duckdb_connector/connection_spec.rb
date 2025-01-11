# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/duckdb_connector/connection"
require "vcr"

RSpec.describe RubyConnectors::DuckdbConnector::Connection do
  subject { described_class.new(config) }

  let(:config) do
    {
      database: "md:my_database",
      credentials: {
        token: ENV.fetch("MOTHERDUCK_TOKEN", nil)
      }
    }
  end

  describe "#connect" do
    it "establishes a connection and performs a simple query" do
      VCR.use_cassette("duckdb/motherduck_connect") do
        expect { subject.connect }.not_to raise_error
      end
    end
  end
end
