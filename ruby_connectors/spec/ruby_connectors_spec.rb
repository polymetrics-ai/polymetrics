# frozen_string_literal: true

RSpec.describe RubyConnectors do
  it "has a version number" do
    expect(RubyConnectors::VERSION).not_to be_nil
  end

  it "connects to the database" do
    expect(RubyConnectors::DB).to be_a(Sequel::Database)
  end
end
