# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/github_connector/client"
require "vcr"

RSpec.describe RubyConnectors::GithubConnector::Client do
  subject { described_class.new(config) }

  let(:config) do
    {
      personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
      repository: "rails/rails"
    }
  end

  describe "#connect", :vcr do
    it "establishes a connection and returns true" do
      VCR.use_cassette("github/github_connect") do
        expect(subject.connect).to be true
      end
    end
  end

  describe "#read", :vcr do
    it "fetches branches data" do
      VCR.use_cassette("github/github_branches") do
        result = subject.read("branches", 1, 2)

        expect(result[:data]).to be_an(Array)
        expect(result[:data].first.to_h.keys).to include(:name, :commit)
        expect(result[:page]).to eq(1)
        expect(result[:per_page]).to eq(2)
        expect(result[:total_pages]).to be > 0
      end
    end

    it "fetches commits data" do
      VCR.use_cassette("github/github_commits") do
        result = subject.read("commits", 1, 2)

        expect(result[:data]).to be_an(Array)
        expect(result[:data].first.to_h.keys).to include(:sha, :commit)
        expect(result[:page]).to eq(1)
        expect(result[:per_page]).to eq(2)
        expect(result[:total_pages]).to be > 0
      end
    end

    it "uses default page and per_page values when not provided" do
      VCR.use_cassette("github/github_branches_default") do
        result = subject.read("branches")

        expect(result[:data]).to be_an(Array)
        expect(result[:page]).to eq(1)
        expect(result[:per_page]).to eq(30)
        expect(result[:total_pages]).to be > 0
      end
    end

    it "raises an ArgumentError for unsupported stream" do
      expect do
        subject.read("unsupported_stream")
      end.to raise_error(ArgumentError, "Unsupported stream: unsupported_stream")
    end
  end

  describe "#catalog" do
    it "returns a hash of schemas" do
      result = subject.catalog

      expect(result).to be_a(Hash)
      expect(result.keys).to include("branches", "commits")
    end

    it "correctly parses JSON schema files" do
      result = subject.catalog

      expect(result["branches"]).to include("title" => "Branches")
      expect(result["commits"]).to include("title" => "Commits")
    end
  end
end
