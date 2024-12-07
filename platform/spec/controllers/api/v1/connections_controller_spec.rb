# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ConnectionsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.where(name: "default").first }
  let(:organization) { workspace.organization }
  let(:source_connector) { create(:connector, workspace: workspace) }
  let(:destination_connector) { create(:connector, workspace: workspace, default_analytics_db: true) }

  before do
    sign_in_and_set_token(user)
  end

  describe "GET #index" do
    context "when user has connections" do
      before do
        create_list(:connection, 3,
                    workspace: workspace,
                    source: source_connector,
                    destination: destination_connector)
        get :index
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all connections for the workspace" do
        expect(response.parsed_body["data"].length).to eq(3)
      end

      it "includes the correct connection attributes" do
        connection_data = response.parsed_body["data"].first
        expected_attributes = %w[
          id name status schedule_type sync_frequency
          namespace stream_prefix configuration
          created_at updated_at
        ]
        expect(connection_data.keys).to include(*expected_attributes)
      end

      it "includes source connector details" do
        connection_data = response.parsed_body["data"].first
        expect(connection_data["source"]).to include(
          "id" => source_connector.id,
          "name" => source_connector.name
        )
      end

      it "includes destination connector details" do
        connection_data = response.parsed_body["data"].first
        expect(connection_data["destination"]).to include(
          "id" => destination_connector.id,
          "name" => destination_connector.name
        )
      end

      it "includes syncs information" do
        connection_data = response.parsed_body["data"].first
        expect(connection_data).to have_key("syncs")
      end
    end

    context "when user has no connections" do
      before { get :index }

      it "returns an empty array" do
        expect(response.parsed_body["data"]).to be_empty
      end
    end

    context "when user is not authenticated" do
      before do
        remove_auth_tokens
        get :index
      end

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#start_sync" do
    let(:connection) do
      create(:connection,
             workspace: workspace,
             source: source_connector,
             destination: destination_connector,
             status: :created)
    end

    context "when successful" do
      before do
        allow_any_instance_of(Connections::StartDataSyncService)
          .to receive(:call)
          .and_return(true)
      end

      it "starts the sync process" do
        post :start_sync, params: { id: connection.id }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({
                                             "data" => {
                                               "message" => "Sync started successfully"
                                             }
                                           })
      end

      it "calls the StartDataSyncService" do
        expect_any_instance_of(Connections::StartDataSyncService)
          .to receive(:call)

        post :start_sync, params: { id: connection.id }
      end
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Connections::StartDataSyncService)
          .to receive(:call)
          .and_raise(StandardError.new("Sync failed"))
      end

      it "handles the error and updates connection status" do
        connection.running!
        post :start_sync, params: { id: connection.id }

        expect(response.parsed_body).to eq({
                                             "error" => { "message" => "Sync failed" }
                                           })
        expect(connection.reload.status).to eq("failed")
      end
    end

    context "when connection is not found" do
      it "returns a not found error" do
        post :start_sync, params: { id: "-1" }

        expect(response.parsed_body).to eq({
                                             "error" => { "message" => "Connection with ID -1 not found in workspace #{workspace.id}" }
                                           })
      end
    end

    context "when user is not authenticated" do
      before { remove_auth_tokens }

      it "returns unauthorized status" do
        post :start_sync, params: { id: connection.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
