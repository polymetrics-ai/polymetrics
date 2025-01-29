# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:pipelines).through(:messages) }
    it { is_expected.to have_many(:chat_connections).dependent(:destroy) }
    it { is_expected.to have_many(:connections).through(:chat_connections) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, completed: 1, failed: 2) }
  end

  describe "scopes" do
    let(:workspace) { create(:workspace) }
    let(:user) { create(:user) }
    let!(:chat1) { create(:chat, workspace: workspace, user: user) }
    let!(:chat2) { create(:chat, workspace: workspace, user: user) }
    let!(:other_workspace_chat) { create(:chat, user: user) }
    let!(:other_user_chat) { create(:chat, workspace: workspace) }

    describe ".in_workspace" do
      it "returns chats for the specified workspace" do
        chats = described_class.in_workspace(workspace.id)

        expect(chats).to include(chat1, chat2)
        expect(chats).not_to include(other_workspace_chat)
      end
    end

    describe ".for_user" do
      it "returns chats for the specified user" do
        chats = described_class.for_user(user.id)

        expect(chats).to include(chat1, chat2, other_workspace_chat)
        expect(chats).not_to include(other_user_chat)
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:chat)).to be_valid
    end

    it "is valid with active status" do
      chat = build(:chat, status: :active)
      expect(chat).to be_valid
      expect(chat).to be_active
    end

    it "is valid with completed status" do
      chat = build(:chat, status: :completed)
      expect(chat).to be_valid
      expect(chat).to be_completed
    end

    it "is valid with failed status" do
      chat = build(:chat, status: :failed)
      expect(chat).to be_valid
      expect(chat).to be_failed
    end
  end
end
