# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ConnectorsController, type: :controller do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:workspace) { create(:workspace, organization:) }
  let!(:user_workspace_membership) do
    create(:user_workspace_membership, user:, workspace:, role: "owner")
  end
  let(:connector) { create(:connector, workspace:) }

  before do
    sign_in_and_set_token(user)
  end

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "returns all connectors for the current user" do
      connectors = create_list(:connector, 3, workspace:)
      get :index
      expect(response.parsed_body["data"]).to match_array(connectors.as_json)
    end
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, params: { id: connector.id }
      expect(response).to be_successful
    end

    it "returns the requested connector" do
      get :show, params: { id: connector.id }
      expect(response.parsed_body["data"]).to eq(connector.as_json)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { attributes_for(:connector) }

    context "with valid params" do
      before do
        allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: true })
      end

      it "creates a new Connector" do
        expect do
          post :create, params: { connector: valid_attributes }
        end.to change(Connector, :count).by(1)
      end

      it "returns a successful response" do
        post :create, params: { connector: valid_attributes }
        expect(response).to be_successful
      end
    end

    context "with invalid params" do
      before do
        allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: false })
      end

      it "returns an error response" do
        post :create, params: { connector: { name: nil } }
        expect(response.parsed_body["error"]["message"]).to eq("Please check your configuration and try again.")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) { { name: "Updated Connector" } }

    context "with valid params" do
      before do
        allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: true })
      end

      it "updates the requested connector" do
        put :update, params: { id: connector.id, connector: new_attributes }
        connector.reload
        expect(connector.name).to eq("Updated Connector")
      end

      it "returns a successful response" do
        put :update, params: { id: connector.id, connector: new_attributes }
        expect(response).to be_successful
      end
    end

    context "with invalid params" do
      before do
        allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: false })
      end

      it "returns an error response" do
        put :update, params: { id: connector.id, connector: { name: nil } }
        expect(response.parsed_body["error"]["message"]).to eq("Please check your configuration and try again.")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested connector" do
      connector_to_delete = create(:connector, workspace:)
      expect do
        delete :destroy, params: { id: connector_to_delete.id }
      end.to change(Connector, :count).by(-1)
    end

    it "returns a no content response" do
      delete :destroy, params: { id: connector.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end
