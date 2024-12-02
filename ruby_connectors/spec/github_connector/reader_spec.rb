# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/github_connector/reader"
require "vcr"

RSpec.describe RubyConnectors::GithubConnector::Reader do
  let(:config) do
    {
      personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
      repository: "rails/rails" # Changed back to 'rails/rails'
    }
  end

  let(:reader) { described_class.new(config) }

  describe "#read" do
    context "when the stream is supported" do
      it "fetches branches data" do
        VCR.use_cassette("github/github_branches") do
          result = reader.read("branches", 1, 2)

          expect(result[:data]).to be_an(Array)
          expect(result[:data].first.to_h.keys).to include(:name, :commit)
          expect(result[:page]).to eq(1)
          expect(result[:per_page]).to eq(2)
          expect(result[:total_pages]).to be.positive?
        end
      end

      it "fetches commits data" do
        VCR.use_cassette("github/github_commits") do
          result = reader.read("commits", 1, 2)

          expect(result[:data]).to be_an(Array)
          expect(result[:data].first.to_h.keys).to include(:sha, :commit)
          expect(result[:page]).to eq(1)
          expect(result[:per_page]).to eq(2)
          expect(result[:total_pages]).to be.positive?
        end
      end

      it "uses default page and per_page values when not provided" do
        VCR.use_cassette("github/github_branches_default") do
          result = reader.read("branches")

          expect(result[:data]).to be_an(Array)
          expect(result[:page]).to eq(1)
          expect(result[:per_page]).to eq(30)
          expect(result[:total_pages]).to be.positive?
        end
      end
    end

    context "when the stream is not supported" do
      it "raises an ArgumentError" do
        expect do
          reader.read("unsupported_stream")
        end.to raise_error(ArgumentError, "Unsupported stream: unsupported_stream")
      end
    end

    context "when the response is not paginated" do
      it "returns total_pages as 1 for repository info" do
        VCR.use_cassette("github/github_repository", record: :new_episodes) do
          result = reader.read("repository")

          expect(result[:data].to_h.keys).to include(:id, :name, :full_name)
          expect(result[:page]).to eq(1)
          expect(result[:per_page]).to eq(30)
          expect(result[:total_pages]).to eq(1)
        end
      end
    end
  end
end
