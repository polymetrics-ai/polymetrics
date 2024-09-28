# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workspace, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:user_workspace_memberships).dependent(:destroy) }
    it { should have_many(:users).through(:user_workspace_memberships) }
    it { should have_many(:connectors).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'name uniqueness' do
      subject { create(:workspace) }
      it { should validate_uniqueness_of(:name).scoped_to(:organization_id).with_message(:unique_within_organization) }
    end

    context 'with very long name' do
      it 'is invalid' do
        workspace = build(:workspace, name: 'a' * 256)
        expect(workspace).to be_invalid
        expect(workspace.errors[:name]).to include("is too long (maximum is 255 characters)")
      end
    end

    context 'with special characters in name' do
      it 'is valid' do
        workspace = build(:workspace, name: 'Test Workspace #1 & Co.')
        expect(workspace).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe '#create_default_duckdb_connector' do
      let(:workspace) { build(:workspace) }
      let(:service_double) { instance_double(Connectors::CreateDefaultAnalyticsDbService) }

      before do
        allow(Connectors::CreateDefaultAnalyticsDbService).to receive(:new).with(workspace).and_return(service_double)
        allow(service_double).to receive(:call)
      end

      it 'calls CreateDefaultAnalyticsDbService after create' do
        expect(service_double).to receive(:call)
        workspace.save
      end

      context 'when service raises an error' do
        before do
          allow(service_double).to receive(:call).and_raise(StandardError.new("Service error"))
        end

        it 'logs the error and does not prevent workspace creation' do
          expect(Rails.logger).to receive(:error).with(/Failed to create default DuckDB connector:/)
          expect { workspace.save }.not_to raise_error
          expect(workspace).to be_persisted
        end
      end
    end
  end

  describe '#default_analytics_db' do
    let(:workspace) { create(:workspace) }

    it 'returns the default analytics db connector' do
      default_connector = create(:connector, workspace: workspace, default_analytics_db: true)
      create(:connector, workspace: workspace, default_analytics_db: false)

      expect(workspace.default_analytics_db).to eq(default_connector)
    end
  end

  describe '#connectors_count' do
    let(:workspace) { create(:workspace) }

    it 'returns the correct count of connectors' do
      create_list(:connector, 3, workspace: workspace)

      expect(workspace.connectors_count).to eq(4)
    end
  end

  describe 'destroying a workspace' do
    let!(:workspace) { create(:workspace) }
    let!(:user_workspace_membership) { create(:user_workspace_membership, workspace: workspace) }
    let!(:connector) { create(:connector, workspace: workspace) }

    it 'destroys associated user_workspace_memberships' do
      expect { workspace.destroy }.to change(UserWorkspaceMembership, :count).by(-1)
    end

    it 'destroys associated connectors' do
      expect { workspace.destroy }.to change(Connector, :count).by(-2)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:workspace)).to be_valid
    end

    it 'creates a workspace with associated organization' do
      workspace = create(:workspace)
      expect(workspace.organization).to be_present
    end
  end
end