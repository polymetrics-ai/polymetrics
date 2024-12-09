# frozen_string_literal: true

# spec/ruby_connectors/core/api_cataloger_spec.rb

require "spec_helper"
require "ruby_connectors/core/api_cataloger"

RSpec.describe RubyConnectors::Core::ApiCataloger do
  let(:schemas_directory) { File.join("spec", "fixtures", "github_schemas") }
  let(:cataloger) { described_class.new(schemas_directory) }

  describe "#catalog" do
    before do
      # Create temporary schema files for testing
      FileUtils.mkdir_p(schemas_directory)
      File.write(File.join(schemas_directory, "branches.json"),
                 '{"name": "branches", "type": "object", "x-stream_name": "branches"}')
      File.write(File.join(schemas_directory, "commits.json"),
                 '{"name": "commits", "type": "object", "x-stream_name": "commits"}')
    end

    after do
      # Clean up temporary files
      FileUtils.rm_rf(schemas_directory)
    end

    it "returns a hash of schemas" do
      result = cataloger.catalog

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly("branches", "commits")
    end

    it "correctly parses JSON schema files" do
      result = cataloger.catalog

      expect(result["branches"]).to eq({ "name" => "branches", "type" => "object", "x-stream_name" => "branches" })
      expect(result["commits"]).to eq({ "name" => "commits", "type" => "object", "x-stream_name" => "commits" })
    end

    context "when a schema file is invalid JSON" do
      let(:logger) { instance_double(Logger) }

      before do
        File.write(File.join(schemas_directory, "invalid.json"), "invalid json")
        allow(Logger).to receive(:new).and_return(logger)
        allow(logger).to receive(:error)
      end

      it "logs the error and continues processing" do
        cataloger.catalog
        expect(logger).to have_received(:error).with(/Failed to parse JSON file.*invalid.json/)
      end

      it "excludes the invalid file from the result" do
        result = cataloger.catalog
        expect(result.keys).not_to include("invalid")
      end
    end

    context "when the schemas directory is empty" do
      let(:empty_directory) { File.join("spec", "fixtures", "empty_schemas") }
      let(:empty_cataloger) { described_class.new(empty_directory) }

      before do
        FileUtils.mkdir_p(empty_directory)
      end

      after do
        FileUtils.rm_rf(empty_directory)
      end

      it "returns an empty hash" do
        expect(empty_cataloger.catalog).to eq({})
      end
    end
  end
end
