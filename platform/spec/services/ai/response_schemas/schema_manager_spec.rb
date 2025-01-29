# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::ResponseSchemas::SchemaManager do
  let(:test_schema_name) { "test_schema" }
  let(:test_schema_content) { { "type" => "object" }.to_json }

  before do
    # Create a test schema file
    File.write(described_class.send(:schema_path, test_schema_name), test_schema_content)
    described_class.instance_variable_set(:@schema_cache, nil) # Reset cache between tests
  end

  after do
    File.delete(described_class.send(:schema_path, test_schema_name))
  rescue StandardError
    nil
  end

  describe ".fetch" do
    it "returns parsed JSON schema" do
      schema = described_class.fetch(test_schema_name)
      expect(schema).to eq(JSON.parse(test_schema_content))
    end

    it "caches loaded schemas" do
      described_class.fetch(test_schema_name)
      expect(File).not_to receive(:read)
      described_class.fetch(test_schema_name)
    end

    context "when schema doesn't exist" do
      it "raises SchemaNotFoundError" do
        expect do
          described_class.fetch("non_existent")
        end.to raise_error(Ai::ResponseSchemas::SchemaNotFoundError)
      end
    end
  end

  describe "method_missing" do
    it "fetches schema using method name" do
      schema = described_class.send(test_schema_name)
      expect(schema).to eq(JSON.parse(test_schema_content))
    end

    it "raises NoMethodError for unknown methods without schema" do
      expect do
        described_class.non_existent_schema
      end.to raise_error(NoMethodError)
    end
  end

  describe ".respond_to_missing?" do
    it "returns true for existing schema names" do
      expect(described_class.respond_to?(test_schema_name)).to be true
    end

    it "returns false for non-existent schema names" do
      expect(described_class.respond_to?(:non_existent)).to be false
    end
  end

  describe "error handling" do
    it "defines SchemaNotFoundError exception" do
      expect(Ai::ResponseSchemas::SchemaNotFoundError).to be < StandardError
    end
  end
end
