# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiResponseWrapperConcern, type: :controller do
  # Properly inherit from ApplicationController
  controller(ApplicationController) do
    include ApiResponseWrapperConcern

    # Skip authentication directly in the controller definition
    skip_before_action :authenticate_user!, raise: false
    skip_before_action :validate_token_presence!, raise: false

    def test_success
      render_success({ message: "Success" }, :created)
    end

    def test_error
      render_error("Bad Request", :bad_request)
    end

    def test_api_response_error
      render_api_response(StandardError.new("Unexpected error"))
    end

    def index
      case params[:error_type]
      when "not_found"
        render_api_response(ActiveRecord::RecordNotFound.new("Record not found"))
      when "standard_error"
        render_api_response(StandardError.new("Unexpected error"))
      else
        render_api_response({ success: true })
      end
    end
  end

  before do
    routes.draw do
      get "test_success" => "anonymous#test_success"
      get "test_error" => "anonymous#test_error"
      get "test_api_response_error" => "anonymous#test_api_response_error"
      get "index" => "anonymous#index"
    end
  end

  describe "#render_success" do
    it "renders a successful JSON response" do
      get :test_success
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq({
                                           "data" => { "message" => "Success" }
                                         })
    end
  end

  describe "#render_error" do
    it "renders an error JSON response" do
      get :test_error
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq({
                                           "error" => { "message" => "Bad Request" }
                                         })
    end
  end

  describe "#render_api_response" do
    context "when result is ActiveRecord::RecordNotFound" do
      it "renders a not found JSON response" do
        get :index, params: { error_type: "not_found" }
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to include(
          "error" => include("message" => "Record not found")
        )
      end
    end

    context "when result is StandardError" do
      before do
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        get :index, params: { error_type: "standard_error" }
        expect(Rails.logger).to have_received(:error).once
                                                     .with("Unexpected error: Unexpected error")
      end

      it "renders an internal server error JSON response" do
        get :index, params: { error_type: "standard_error" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body).to include(
          "error" => include("message" => "Unexpected error")
        )
      end
    end

    context "when result is successful" do
      it "renders a success JSON response" do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(
          "data" => include("success" => true)
        )
      end
    end
  end
end
