require 'spec_helper'
require 'ruby_connectors/github_connector/cataloger'

RSpec.describe RubyConnectors::GithubConnector::Cataloger do
  let(:cataloger) { described_class.new }

  describe '#catalog' do
    it 'returns a hash of schemas' do
      result = cataloger.catalog

      expect(result).to be_a(Hash)
      expect(result.keys).to include('branches', 'commits')
    end

    it 'correctly parses JSON schema files' do
      result = cataloger.catalog

      expect(result['branches']).to include('title' => 'Branches')
      expect(result['commits']).to include('title' => 'Commits')
    end
  end
end