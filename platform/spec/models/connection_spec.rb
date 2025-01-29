# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connection, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace) }
    it { is_expected.to belong_to(:source).class_name("Connector") }
    it { is_expected.to belong_to(:destination).class_name("Connector") }
    it { is_expected.to have_many(:syncs).dependent(:destroy) }
    it { is_expected.to have_many(:chat_connections).dependent(:destroy) }
    it { is_expected.to have_many(:chats).through(:chat_connections) }
  end

  describe "validations" do
    subject { build(:connection) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:workspace_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:schedule_type) }
    it { is_expected.to validate_presence_of(:namespace) }

    it "is valid with a valid namespace" do
      connection = build(:connection, namespace: :user_defined)
      expect(connection).to be_valid
    end

    it "is invalid with an invalid namespace" do
      expect { build(:connection, namespace: :invalid_namespace) }.to raise_error(ArgumentError)
    end

    context "when schedule_type is scheduled or cron" do
      it "requires sync_frequency" do
        connection = build(:connection, schedule_type: :scheduled, sync_frequency: nil)
        expect(connection).not_to be_valid
        expect(connection.errors[:sync_frequency]).to include("can't be blank")
      end
    end

    context "when schedule_type is manual" do
      it "does not require sync_frequency" do
        connection = build(:connection, schedule_type: :manual, sync_frequency: nil)
        expect(connection).to be_valid
      end
    end
  end

  describe "enums" do
    subject(:connection) { described_class.new }

    it { is_expected.to define_enum_for(:status).with_values(created: 0, failed: 1, running: 2, paused: 3, healthy: 4) }
    it { is_expected.to define_enum_for(:schedule_type).with_values(scheduled: 0, cron: 1, manual: 2) }

    it {
      expect(connection).to define_enum_for(:namespace).with_values(system_defined: 0,
                                                                    source_defined: 1,
                                                                    destination_defined: 2,
                                                                    user_defined: 3)
    }
  end

  describe "state machine" do
    let(:connection) { create(:connection) }

    describe "transitions" do
      it "logs failure when transitioning to failed" do
        expect(Rails.logger).to receive(:error).with(/Connection #{connection.id} failed at/)
        connection.start!
        connection.fail!
      end

      it "logs recovery when transitioning from failed to healthy" do
        connection.start!
        connection.fail!
        expect(Rails.logger).to receive(:info).with(/Connection #{connection.id} recovered at/)
        connection.recover!
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:connection)).to be_valid
    end

    it "is valid with manual schedule type and no sync frequency" do
      expect(build(:connection, schedule_type: :manual, sync_frequency: nil)).to be_valid
    end
  end

  describe "status transitions" do
    let(:connection) { create(:connection) }

    it "has initial state of created" do
      expect(connection.created?).to be true
    end

    describe "#start" do
      it "transitions from created to running" do
        expect(connection.start!).to be true
        expect(connection.running?).to be true
      end

      it "transitions from healthy to running" do
        connection.status = :healthy
        expect(connection.start!).to be true
        expect(connection.running?).to be true
      end

      it "transitions from failed to running" do
        connection.status = :failed
        expect(connection.start!).to be true
        expect(connection.running?).to be true
      end

      it "transitions from paused to running" do
        connection.status = :paused
        expect(connection.start!).to be true
        expect(connection.running?).to be true
      end
    end

    describe "#pause" do
      it "transitions from running to paused" do
        connection.status = :running
        expect(connection.pause!).to be true
        expect(connection.paused?).to be true
      end

      it "transitions from healthy to paused" do
        connection.status = :healthy
        expect(connection.pause!).to be true
        expect(connection.paused?).to be true
      end
    end

    describe "#resume" do
      it "transitions from paused to running" do
        connection.status = :paused
        expect(connection.resume!).to be true
        expect(connection.running?).to be true
      end
    end

    describe "#complete" do
      it "transitions from running to healthy" do
        connection.status = :running
        expect(connection.complete!).to be true
        expect(connection.healthy?).to be true
      end
    end

    describe "#fail" do
      it "transitions from running to failed" do
        connection.status = :running
        expect(connection.fail!).to be true
        expect(connection.failed?).to be true
      end

      it "transitions from healthy to failed" do
        connection.status = :healthy
        expect(connection.fail!).to be true
        expect(connection.failed?).to be true
      end

      it "logs failure message" do
        connection.status = :running
        current_time = Time.current
        allow(Time).to receive(:current).and_return(current_time)

        expect(Rails.logger).to receive(:error).with("Connection #{connection.id} failed at #{current_time}")
        connection.fail!
      end
    end

    describe "#recover" do
      it "transitions from failed to healthy" do
        connection.status = :failed
        expect(connection.recover!).to be true
        expect(connection.healthy?).to be true
      end

      it "logs recovery message" do
        connection.status = :failed
        current_time = Time.current
        allow(Time).to receive(:current).and_return(current_time)

        expect(Rails.logger).to receive(:info).with("Connection #{connection.id} recovered at #{current_time}")
        connection.recover!
      end
    end
  end

  describe "edge cases" do
    it "is invalid with a name longer than 255 characters" do
      connection = build(:connection, name: "a" * 256)
      expect(connection).to be_invalid
      expect(connection.errors[:name]).to include("is too long (maximum is 255 characters)")
    end

    it "allows the same name in different workspaces" do
      connection1 = create(:connection)
      connection2 = build(:connection, name: connection1.name, workspace: create(:workspace))
      expect(connection2).to be_valid
    end

    it "handles large JSON configuration" do
      large_config = { "data" => "a" * 1_000_000 } # 1MB of data
      connection = create(:connection, configuration: large_config)
      expect(connection.reload.configuration).to eq(large_config)
    end

    it "handles nil namespace" do
      connection = build(:connection, namespace: nil)
      expect(connection).not_to be_valid
      expect(connection.errors[:namespace]).to include("can't be blank")
    end

    it "prevents changing namespace to nil" do
      connection = create(:connection, namespace: :user_defined)
      connection.namespace = nil
      expect(connection).not_to be_valid
      expect(connection.errors[:namespace]).to include("can't be blank")
    end

    it "allows changing namespace between valid values" do
      connection = create(:connection, namespace: :user_defined)
      expect { connection.update!(namespace: :system_defined) }.not_to raise_error
      expect(connection.reload.namespace).to eq("system_defined")
    end

    it "prevents setting an out-of-range integer value for namespace" do
      expect { build(:connection, namespace: 99) }.to raise_error(ArgumentError)
    end

    it "maintains namespace value after other attribute updates" do
      connection = create(:connection, namespace: :destination_defined)
      connection.update!(name: "New Name")
      expect(connection.reload.namespace).to eq("destination_defined")
    end
  end

  describe "namespace behavior" do
    let(:connection) { create(:connection) }

    it "defaults to system_defined namespace if not specified" do
      expect(connection.namespace).to eq("system_defined")
    end

    it "allows changing namespace" do
      connection.update(namespace: :source_defined)
      expect(connection.reload.namespace).to eq("source_defined")
    end

    describe "querying by namespace" do
      let(:system_defined_connection) { create(:connection, namespace: :system_defined) }
      let(:source_defined_connection) { create(:connection, namespace: :source_defined) }
      let(:destination_defined_connection) { create(:connection, namespace: :destination_defined) }

      it "allows querying system_defined namespace" do
        expect(Connection.system_defined).to include(system_defined_connection)
      end

      it "allows querying source_defined namespace" do
        expect(Connection.source_defined).to include(source_defined_connection)
      end

      it "allows querying destination_defined namespace" do
        expect(Connection.destination_defined).to include(destination_defined_connection)
      end

      it "does not include connections from other namespaces" do
        expect(Connection.system_defined).not_to include(source_defined_connection, destination_defined_connection)
      end
    end
  end
end
