# frozen_string_literal: true

module ApiResponseWrapperConcern
  extend ActiveSupport::Concern

  def render_api_response(result, status = :ok)
    case result
    when ActiveRecord::RecordNotFound
      handle_error_response(result.message, :not_found)
    when StandardError
      handle_error_response(result.message)
    else
      render json: { data: result }, status: status
    end
  end

  def render_success(data, status = :ok)
    render json: { data: data }, status: status
  end

  def render_error(message, status = :bad_request)
    response_body = {
      error: {
        message: message
      }
    }

    render json: response_body, status: status
  end

  private

  def handle_error_response(message, status = :internal_server_error)
    Rails.logger.error("Unexpected error: #{message}") if status == :internal_server_error
    render_error(message, status)
  end
end
