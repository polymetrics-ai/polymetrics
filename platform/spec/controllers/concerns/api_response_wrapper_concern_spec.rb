# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiResponseWrapperConcern, type: :controller do
  controller(ApplicationController) do
    include described_class

    def test_success
      render_success({ id: 1, name: "Test" }, :created)
    end

    def test_error
      render_error("Error message", status: :bad_request)
    end

    def test_api_response_success
      render_api_response({ id: 1, name: "Test" }, :ok)
    end

    def test_api_response_not_found
      render_api_response(ActiveRecord::RecordNotFound.new("Record not found"), :not_found)
    end

    def test_api_response_error
      render_api_response(StandardError.new("Unexpected error"), :internal_server_error)
    end
  end

  before do
    routes.draw do
      get "test_success" => "anonymous#test_success"
      get "test_error" => "anonymous#test_error"
      get "test_api_response_success" => "anonymous#test_api_response_success"
      get "test_api_response_not_found" => "anonymous#test_api_response_not_found"
      get "test_api_response_error" => "anonymous#test_api_response_error"
    end
  end

  describe "#render_success" do
    it "renders a successful JSON response" do
      get :test_success
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq({ "data" => { "id" => 1, "name" => "Test" } })
    end
  end

  describe "#render_error" do
    it "renders an error JSON response" do
      get :test_error
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq({ "error" => { "message" => "Error message" } })
    end
  end

  describe "#render_api_response" do
    context "when result is successful" do
      it "renders a successful JSON response" do
        get :test_api_response_success
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "data" => { "id" => 1, "name" => "Test" } })
      end
    end

    context "when result is ActiveRecord::RecordNotFound" do
      it "renders a not found JSON response" do
        get :test_api_response_not_found
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq({ "error" => { "message" => "Record not found" } })
      end
    end

    context "when result is StandardError" do
      it "renders an internal server error JSON response" do
        allow(Rails.logger).to receive(:error)
        get :test_api_response_error
        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body).to eq({ "error" => { "message" => "Unexpected error" } })
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with("Unexpected error: Unexpected error")
        expect(Rails.logger).to receive(:error)
        get :test_api_response_error
      end
    end
  end
end
