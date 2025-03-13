# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:chat) }
    it { is_expected.to have_one(:pipeline).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:message_type) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, system: 1, assistant: 2) }
    it { is_expected.to define_enum_for(:message_type).with_values(text: 0, pipeline: 1, question: 2, summary: 3) }
  end

  describe "scopes" do
    describe ".pending_questions" do
      let!(:pending_question) { create(:message, :question, answered: false) }
      let!(:answered_question) { create(:message, :question, answered: true) }
      let!(:text_message) { create(:message, :text) }
      let!(:pipeline_message) { create(:message, :pipeline) }

      it "returns only unanswered questions" do
        pending_messages = described_class.pending_questions

        expect(pending_messages).to include(pending_question)
        expect(pending_messages).not_to include(answered_question)
        expect(pending_messages).not_to include(text_message)
        expect(pending_messages).not_to include(pipeline_message)
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:message)).to be_valid
    end

    describe "role traits" do
      it "creates user message" do
        message = create(:message, :user)
        expect(message).to be_user
      end

      it "creates system message" do
        message = create(:message, :system)
        expect(message).to be_system
      end

      it "creates assistant message" do
        message = create(:message, :assistant)
        expect(message).to be_assistant
      end
    end

    describe "type traits" do
      it "creates text message" do
        message = create(:message, :text)
        expect(message).to be_text
      end

      it "creates pipeline message" do
        message = create(:message, :pipeline)
        expect(message).to be_pipeline
      end

      it "creates question message" do
        message = create(:message, :question)
        expect(message).to be_question
      end
    end

    describe "pipeline trait" do
      it "creates message with associated pipeline" do
        message = create(:message, :with_pipeline)
        expect(message.pipeline).to be_present
      end
    end
  end

  describe "message lifecycle" do
    context "when message is destroyed" do
      let!(:message) { create(:message, :with_pipeline) }

      it "destroys associated pipeline" do
        expect { message.destroy }.to change(Pipeline, :count).by(-1)
      end
    end
  end
end
