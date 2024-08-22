# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ApiResponseWrapperConcern

  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from StandardError, with: :handle_error

  protect_from_forgery with: :null_session

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[organization_name name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[organization_name name])
  end

  private

  def handle_error(error)
    render_api_response(error, :internal_server_error)
    Rails.error.report(error) # TODO: Add Sentry using a error reporting service
  end
end
