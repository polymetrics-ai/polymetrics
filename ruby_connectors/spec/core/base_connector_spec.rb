# frozen_string_literal: true

require "ruby_connectors/core/base_connector"

RSpec.describe RubyConnectors::Core::BaseConnector do
  let(:connector) { described_class.new(config) }
  let(:config) { { key: "value" } }

  it "initializes with config" do
    expect(connector.instance_variable_get(:@config)).to eq(config)
  end

  it "raises NotImplementedError for connect" do
    expect { connector.connect }.to raise_error(NotImplementedError)
  end

  it "raises NotImplementedError for read" do
    expect { connector.read }.to raise_error(NotImplementedError)
  end

  it "raises NotImplementedError for write" do
    expect { connector.write("data") }.to raise_error(NotImplementedError)
  end
end
