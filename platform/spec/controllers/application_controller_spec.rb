# frozen_string_literal: true

# spec/controllers/application_controller_spec.rb

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "Hello, World!"
    end
  end

  describe "included modules" do
    it "includes DeviseTokenAuth::Concerns::SetUserByToken" do
      expect(described_class.ancestors).to include(DeviseTokenAuth::Concerns::SetUserByToken)
    end

    it "includes ApiResponseWrapperConcern" do
      expect(described_class.ancestors).to include(ApiResponseWrapperConcern)
    end
  end

  describe "CSRF protection" do
    it "sets protect_from_forgery with null_session" do
      expect(controller.class.forgery_protection_strategy).to be_present
      expect(controller.class.forgery_protection_strategy.name).to include("NullSession")
    end
  end

  describe "#configure_permitted_parameters" do
    let(:devise_parameter_sanitizer) { instance_double(Devise::ParameterSanitizer) }

    before do
      allow(controller).to receive_messages(devise_parameter_sanitizer: devise_parameter_sanitizer,
                                            devise_controller?: true)
    end

    it "permits :organization_name for sign up and account update" do
      allow(devise_parameter_sanitizer).to receive(:permit)
      controller.send(:configure_permitted_parameters)
      expect(devise_parameter_sanitizer).to have_received(:permit).with(:sign_up, keys: %i[organization_name name])
      expect(devise_parameter_sanitizer).to have_received(:permit).with(:account_update,
                                                                        keys: %i[organization_name name])
    end
  end

  describe "error handling" do
    controller do
      skip_before_action :validate_token_presence!, only: [:index]

      def index
        raise StandardError, "Test error"
      end
    end

    before do
      allow(Rails.error).to receive(:report)
    end

    it "renders API response and reports error" do
      routes.draw { get "index" => "anonymous#index" }

      get :index

      expect(Rails.error).to have_received(:report)
      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body).to include(
        "error" => include("message" => "Test error")
      )
    end
  end
end
