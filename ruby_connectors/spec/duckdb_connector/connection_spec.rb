require "spec_helper"
require "ruby_connectors/duckdb_connector/connection"
require "vcr"

RSpec.describe RubyConnectors::DuckdbConnector::Connection do
  subject { described_class.new(config) }

  let(:config) do
    {
      database: 'md:my_database',
      credentials: {
        motherduck: {
          token: ENV['MOTHERDUCK_TOKEN']
        }
      }
    }
  end

  describe "#connect", :vcr do
    it "establishes a connection and performs a simple query" do
      VCR.use_cassette("motherduck_connect") do
        expect { subject.connect }.not_to raise_error
      end
    end
  end
end