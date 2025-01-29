# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatConnection, type: :model do
  subject { build(:chat_connection, chat: chat, connection: connection) }

  let(:chat) { create(:chat) }
  let(:connection) { create(:connection) }

  describe "associations" do
    it { is_expected.to belong_to(:chat) }
    it { is_expected.to belong_to(:connection) }
  end

  describe "validations" do
    it "validates uniqueness of chat_id scoped to connection_id" do
      create(:chat_connection, chat: chat, connection: connection)
      duplicate = build(:chat_connection, chat: chat, connection: connection)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:chat_id]).to include("has already been taken")
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(subject).to be_valid
    end

    it "creates valid associations" do
      chat_connection = create(:chat_connection)
      expect(chat_connection.chat).to be_persisted
      expect(chat_connection.connection).to be_persisted
    end
  end
end
