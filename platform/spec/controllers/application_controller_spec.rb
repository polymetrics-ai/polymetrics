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
      def index
        raise StandardError, "Test error"
      end
    end

    it "rescues from StandardError and calls handle_error" do
      allow(controller).to receive(:handle_error)
      get :index
      expect(controller).to have_received(:handle_error)
    end

    it "renders API response and reports error" do
      error = StandardError.new("Test error")
      allow(controller).to receive(:render_api_response)
      allow(Rails.error).to receive(:report)
      controller.send(:handle_error, error)
      expect(controller).to have_received(:render_api_response).with(error, :internal_server_error)
      expect(Rails.error).to have_received(:report).with(error)
    end
  end
end
