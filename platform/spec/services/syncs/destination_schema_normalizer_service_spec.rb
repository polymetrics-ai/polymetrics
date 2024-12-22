# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::DestinationSchemaNormalizerService do
  let(:workspace) { create(:workspace) }
  let(:source_connector) { create(:connector, workspace: workspace) }
  let(:destination_connector) { create(:connector, workspace: workspace, integration_type: "database") }
  let(:connection) { create(:connection, workspace: workspace, source: source_connector, destination: destination_connector) }
  let(:sync) { create(:sync, connection: connection, stream_name: "users", schema: source_schema) }
  let(:service) { described_class.new(sync) }

  let(:source_schema) do
    {
      properties: {
        id: { type: "integer" },
        name: { type: "string" },
        email: { type: "string" },
        created_at: { type: "string", format: "date-time" },
        is_active: { type: "boolean" },
        score: { type: "number" },
        nullable_field: { type: %w[null string] }
      }
    }
  end

  describe "#call" do
    context "when destination is not a database" do
      before do
        destination_connector.update!(integration_type: "api")
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end

    context "when destination is a database" do
      let(:mapping_json) do
        {
          default: "VARCHAR",
          type_mappings: {
            integer: "BIGINT",
            number: "DOUBLE",
            string: "VARCHAR",
            boolean: "BOOLEAN"
          },
          format_mappings: {
            "date-time": "TIMESTAMP",
            date: "DATE",
            time: "TIME"
          }
        }
      end

      let(:metadata_json) do
        {
          features: {
            schema_support: true
          }
        }
      end

      before do
        allow(File).to receive(:read).with(anything) do |path|
          if path.to_s.end_with?("mapping.json")
            mapping_json.to_json
          elsif path.to_s.end_with?("metadata.json")
            metadata_json.to_json
          end
        end
      end

      it "returns all required schema keys" do
        result = service.call

        expect(result).to include(
          :database,
          :schema_name,
          :table_name,
          :table_schema,
          :mapping
        )
      end

      it "generates correct database and schema names" do
        result = service.call

        expect(result[:database]).to match(/\w+_test$/)
        expect(result[:schema_name]).to match(/^source_\w+_[a-f0-9]{8}$/)
        expect(result[:table_name]).to eq("users")
      end

      it "generates correct table schema" do
        result = service.call

        expect(result[:table_schema]).to eq(
          "_polymetrics_id" => "VARCHAR",
          "_polymetrics_extracted_at" => "TIMESTAMP",
          "id" => "BIGINT",
          "name" => "VARCHAR",
          "email" => "VARCHAR",
          "created_at" => "TIMESTAMP",
          "is_active" => "BOOLEAN",
          "score" => "DOUBLE",
          "nullable_field" => "VARCHAR"
        )
      end

      it "includes correct mapping entries" do
        result = service.call

        expect(result[:mapping]).to include(
          {
            from: "_polymetrics_id",
            to: "_polymetrics_id",
            type: "signature"
          },
          {
            from: "_polymetrics_extracted_at",
            to: "_polymetrics_extracted_at",
            type: "current_timestamp"
          }
        )
      end

      context "when schema support is disabled" do
        let(:metadata_json) do
          {
            "features" => {
              "schema_support" => false
            }
          }
        end

        it "returns nil for schema_name and prefixes table name" do
          result = service.call

          expect(result[:schema_name]).to be_nil
          expect(result[:table_name]).to match(/source_\w+_[a-f0-9]{8}_users/)
        end
      end

      context "when mapping file is not found" do
        before do
          allow(File).to receive(:read).with(/mapping\.json/).and_raise(StandardError)
        end

        it "uses default mappings" do
          result = service.call

          expect(result[:table_schema]).to include(
            "id" => "BIGINT",
            "name" => "VARCHAR"
          )
        end
      end
    end
  end

  describe "private methods" do
    describe "#extract_non_null_type" do
      it "handles single type" do
        result = service.send(:extract_non_null_type, "string")
        expect(result).to eq("string")
      end

      it "handles array with null type" do
        result = service.send(:extract_non_null_type, %w[null string])
        expect(result).to eq("string")
      end

      it "returns string for empty array" do
        result = service.send(:extract_non_null_type, [])
        expect(result).to eq("string")
      end
    end

    describe "#generate_schema_name" do
      it "generates a valid schema name" do
        result = service.send(:generate_schema_name)
        expect(result).to match(/^source_[a-z0-9_]+_[a-f0-9]{8}$/)
      end
    end

    describe "#generate_database_name" do
      it "generates a valid database name" do
        result = service.send(:generate_database_name)
        expect(result).to match(/^[a-z0-9_]+_test$/)
      end
    end
  end
end
