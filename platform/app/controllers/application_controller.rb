# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ApiResponseWrapperConcern

  protect_from_forgery with: :null_session

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :validate_token_presence!

  rescue_from StandardError, with: :handle_error
  rescue_from SecurityError, with: :handle_unauthorized

  protected

  def validate_token_presence!
    return if skip_token_validation? || valid_token_present?

    render_api_response({ message: "Unauthorized access" }, :unauthorized)
  end

  def valid_token_present?
    token = request.headers["access-token"]
    client = request.headers["client"]
    uid = request.headers["uid"]

    return false unless token && client && uid

    user = User.find_by(uid: uid)
    user&.valid_token?(token, client)
  end

  def skip_token_validation?
    devise_controller? ||
      (Rails.env.test? && self.class.name.include?("Anonymous")) ||
      (respond_to?(:controller_path) && controller_path == "rails/health")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[organization_name name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[organization_name name])
  end

  def current_workspace
    @current_workspace ||= find_workspace
  end

  private

  def handle_unauthorized(error)
    render_api_response({ message: error.message }, :unauthorized)
  end

  def handle_error(error)
    render_api_response(error, :internal_server_error)
    Rails.error.report(error)
  end

  def find_workspace
    return nil unless user_signed_in?

    find_workspace_by_header ||
      find_workspace_by_name ||
      find_default_workspace
  end

  def find_workspace_by_header
    return nil unless request.headers["Workspace-Id"]

    current_user.workspaces.find_by(id: request.headers["Workspace-Id"])
  end

  def find_workspace_by_name
    current_user.workspaces.find_by(name: "default")
  end

  def find_default_workspace
    current_user.workspaces.first
  end
end
