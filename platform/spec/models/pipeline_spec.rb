# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pipeline, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:message) }
    it { is_expected.to have_many(:pipeline_actions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, running: 1, completed: 2, failed: 3) }
  end

  describe "ordered pipeline actions" do
    it "returns pipeline actions in correct order" do
      pipeline = create(:pipeline)
      create(:pipeline_action, pipeline: pipeline, order: 2)
      create(:pipeline_action, pipeline: pipeline, order: 1)
      create(:pipeline_action, pipeline: pipeline, order: 3)

      expect(pipeline.pipeline_actions.map(&:order)).to eq([1, 2, 3])
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:pipeline)).to be_valid
    end

    describe "traits" do
      it "creates pipeline with running status" do
        pipeline = create(:pipeline, :running)
        expect(pipeline).to be_running
      end

      it "creates pipeline with completed status" do
        pipeline = create(:pipeline, :completed)
        expect(pipeline).to be_completed
      end

      it "creates pipeline with failed status" do
        pipeline = create(:pipeline, :failed)
        expect(pipeline).to be_failed
      end

      it "creates pipeline with actions" do
        pipeline = create(:pipeline, :with_actions, actions_count: 3)
        expect(pipeline.pipeline_actions.count).to eq(3)
      end
    end
  end
end
